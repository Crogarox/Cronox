package Cronox;
use strict;
use warnings;
use UNIVERSAL::require;
use Class::Trigger;
use Fcntl qw/:flock/;
use POSIX;
use Sys::Hostname;
use Time::HiRes ();
use IPC::Open3 qw/open3/;
use Class::Accessor::Lite (
    rw => [qw/cmd opts pid pidfile config plugins plugin_opts
              exit_code started_on finished_on/],
);
use Cronox::Util;
use Cronox::Config;

our $VERSION = '0.02';

sub new {
    my ( $class, $cmd, $opts, $plugin_opts ) = @_;

    my $self = bless {
        config      => Cronox::Config->current,
        cmd         => $cmd,
        opts        => $opts || {},
        plugin_opts => $plugin_opts || {},
        _output     => [],
        host        => hostname(),
        pid         => "",
        pidfile     => "",
        exit_code   => -1,
        started_on  => 0,
        finished_on => 0,
    }, $class;

    map {
        $self->diag("$_:$ENV{$_}")
            if ($ENV{$_} && -f $ENV{$_})
    } qw/CRONOX_CONFIG CRONOX_LOCAL_CONFIG/;

    $self;
}

sub debug { $ENV{CRONOX_DEBUG} || $_[0]->opts->{debug} }
sub diag  { chomp $_[1]; print STDERR $_[1],"\n" if $_[0]->debug }

sub initialize {
    my $self = shift;

    $self->started_on(time);

    my $tmpdir = Cronox::Config->param('tmpdir') || '/tmp/cronox';
    unless (-d $tmpdir) {
        mkdir $tmpdir;
        $self->diag("create: $tmpdir");
    }

    my $script_name = script_name($self->cmd);
    if ($script_name ne "") {
        $self->pidfile("$tmpdir/$script_name.pid");
    } else {
        $self->pidfile("$tmpdir/cronox_pid");
    }
}

sub finalize {
    my $self = shift;

    if ($self->exit_code ne -2 && -f $self->pidfile) {
        unlink $self->pidfile;
        $self->diag(sprintf '%s removed', $self->pidfile);
    }
}

sub load_plugins {
    my $self = shift;

    my $plugins = Cronox::Config->param('plugins') || {};
    for (@$plugins) {
        next if $_->{disable};
        my $module = $_->{module} || next;
        my $config = $_->{config} || {};

        my $module_name =
          ( index( $module, '+' ) ne 0 )
          ? sprintf( '%s::%s::%s', __PACKAGE__, 'Plugin', $module )
          : substr( $module, 1 );

        my @opts = ();
        (my $opt_key = lc $module) =~ s/::/_/g;
        for my $opt (@{ $self->plugin_opts }) {
            next unless $opt =~ /^$opt_key:(.+)$/;
            $self->diag("  load plugin-opt $1");
            push @opts, $1;
        }

        $module_name->require;
        $module_name->new($config, \@opts)->register_hook($self);
        $self->diag("$module_name is loaded");
    }
}

sub run {
    my $self = shift;

    $self->initialize;
    $self->load_plugins;
    $self->call_trigger('init');

    my $cancelled;
    eval {
        local $SIG{INT}  = sub { $cancelled = 1; die "SIGINT\n" };
        local $SIG{HUP}  = sub { die "SIGHUP\n"  };
        local $SIG{TERM} = sub { die "SIGTERM\n" };
        $self->exec;
    };

    # caught signal handling
    if (my $e = $@) {
        if ($cancelled && $e eq "SIGINT\n" ) {
            kill INT => $self->childpid;
            $self->readline("cancelled.\n");
            $self->exit_code(0); # what should I do...
        } else {
            if ($e =~ /^SIG(HUP|TERM)\n$/) {
                my $sig = $1;
                $self->readline("caught $e");
                kill $sig => $self->childpid;
                $self->readline("sent $sig signal to child process.");
            } else {
                $self->readline("unknown error: $e");
                kill KILL => $self->childpid;
                $self->readline("sent KILL signal to child process.");
            }
        }
        chomp $e;
        $self->call_trigger('error', $e);
    }

    if ($self->exit_code < 0) {
        $self->readline("failed to execute command. $!");
    } elsif ($self->exit_code & 127) {
        $self->exit_code($self->exit_code & 127);
        $self->readline("command died with signal:".$self->exit_code);
    } else {
        $self->exit_code($self->exit_code >> 8);
    }
    $self->call_trigger('finalize');
    $self->finalize;
    $self;
}

sub childpid {
    my $self = shift;
    open(my $fh, '<', $self->pidfile) or die 'cannot open the file';
    my $pid = do { local $/; <$fh> };
    close $fh;
    $pid;
}

sub exec {
    my $self = shift;

    my ( $wtr, $rdr, @output );
    my $finished = 0;

    if ($self->check_dualboot) {
        my $msg = sprintf '%s is exist.', $self->pidfile;
        $self->readline($msg);
        $self->diag($msg);
        $self->exit_code(-2);
        return $self;
    }

    my $pid = open3 $wtr, $rdr, 0, @{ $self->cmd };
    close $wtr;

    $self->pidfile($self->pidfile.".$pid") if (-f $self->pidfile);

    open(my $fh, '>', $self->pidfile) or die 'cannot open the file';
    flock( $fh, LOCK_EX | LOCK_NB )   or die 'cannot get the lock';
    print $fh $pid                    or die 'cannot write file';
    flock( $fh, LOCK_UN )             or die 'cannot get the lock';
    close $fh;

    while (1) {
        last if $finished;

        my $waitpid = waitpid( $pid, WNOHANG );

        if ( $waitpid ne 0 && $waitpid ne -1 ) {
            $self->exit_code($?);
        }
        if ( $waitpid eq -1 ) {
            $finished = 1;
            next;
        }
        while ( my $line = <$rdr> ) {
            $self->readline($line);
        }
        Time::HiRes::usleep(1);
    }
    $self->finished_on(time);
    $self->readline("execution time(s):".($self->finished_on - $self->started_on))
        if ($self->started_on && $self->finished_on);
    $self;
}

sub readline {
    my ($self, $line) = @_;

    chomp $line; $line .= "\n";
    print STDERR $line if Cronox::Config->param('print_stderr');

    $self->call_trigger( 'readline', $line );
    $self->add_output($line);
}

sub check_dualboot    { !$_[0]->config->{can_dualboot} && -f $_[0]->pidfile }

sub cmdstr     { join ' ', @{ $_[0]->cmd } }
sub output     { join( "", @{ $_[0]->{_output} } ) }
sub add_output { push @{ $_[0]->{_output} }, @_ }

1;

__END__

=head1 NAME

Cronox - 

=head1 SYNOPSIS

  use Cronox;

=head1 DESCRIPTION

Cronox is

=head1 AUTHOR

Kosuke Arisawa E<lt>arisawa@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
