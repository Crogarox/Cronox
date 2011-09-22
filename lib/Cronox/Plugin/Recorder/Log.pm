package Cronox::Plugin::Recorder::Log;
use strict;
use warnings;
use IO::Dir;
use Time::Piece;
use Time::Seconds;
use Fcntl qw(:flock);
use base qw(Cronox::Plugin);
use Cronox::Util;

sub init {
    my ($self, $cx) = @_;

    my $opts = $self->{opts};
    my $logdir = $opts->{logdir} || $self->config->{dir};
    $logdir = ( index( $logdir, '/' ) ne 0 ) ? path_to($logdir) : $logdir;
    mkdir $logdir unless -d $logdir;

    my $logfile = $opts->{logfile} || $self->config->{logfile} || script_name( $cx->cmd ) || parse_command( $cx->cmd );
    my $errfile = $opts->{errfile} || $self->config->{errfile} || 'cronox_err';

    $self->logdir($logdir);
    $self->logfile(_get_filename($logdir, $logfile));
    $self->errfile(_get_filename($logdir, $errfile));

    map { $cx->diag(sprintf '%s:%s - %s', __PACKAGE__, $_, $self->$_) }
        qw(logdir logfile errfile);

    # print executed log
    my $start_log = sprintf(
        "%s\texecute command: %s",
        now(),
        $cx->cmdstr,
    );
    unless ($ENV{HARNESS_ACTIVE}) {
        $cx->diag($start_log);
        $self->logging($start_log);
    }
    $self;
}

sub readline {
    my ($self, $cx, $line) = @_;
    $self->logging(now() . "\t$line");
}

sub error {
    my ($self, $cx, $line) = @_;
    $self->logging(join("\t", now(), $cx->cmdstr, $line), 'error');
}

sub finalize {
    my ($self, $cx) = @_;

    my $finish_log = sprintf(
        "%s\tfinished. exit_code: %s",
        now(),
        $cx->exit_code,
    );
    unless ($ENV{HARNESS_ACTIVE}) {
        $cx->diag($finish_log);
        $self->logging($finish_log);
    }
    $self->remove_log($cx);
}

sub logging {
    my ($self, $line, $error) = @_;

    chomp $line; $line .= "\n";
    my $logfile =
      ( defined $error && $error eq 'error' ) ? $self->errfile : $self->logfile;

    open my $fh, '>>', $logfile or die $!;
    flock( $fh, LOCK_EX | LOCK_NB ) or die 'cannot get the lock';
    print $fh $line or die 'cannot write file';
    flock( $fh, LOCK_UN ) or die 'cannot get the lock';
    close $fh;
}

sub _get_filename { sprintf( '%s/%s.log.%s', $_[0], $_[1], now('ymd') ) }
sub logdir  { $_[0]->{logdir}  = $_[1] if $_[1]; $_[0]->{logdir}  }
sub logfile { $_[0]->{logfile} = $_[1] if $_[1]; $_[0]->{logfile} }
sub errfile { $_[0]->{errfile} = $_[1] if $_[1]; $_[0]->{errfile} }

sub remove_log {
    my ($self, $cx) = @_;

    my $days = $self->{opts}{retension_days} || $self->config->{retention_days};
    return unless $days;

    my $save_time = Time::Piece::localtime() - $days * ONE_DAY;
    my $save_ymd  = $save_time->ymd("");

    my $dir_handle = IO::Dir->new($self->logdir) or die;
    while (my $file = $dir_handle->read) {
        next unless ($file =~ /.+\.(\d{8})$/);
        my $ymd = $1;
        if ($save_ymd > $ymd) {
            my $remove_file = sprintf '%s/%s', $self->logdir, $file;
            unlink $remove_file or warn "Can't remove $remove_file:$1";
            $cx->diag("removed $remove_file");
        }
    }
}

1;

__END__

=head1 NAME

B<Cronox::Plugin::Recorder::Log> - To log all output

=head1 VERSION

0.01

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Kosuke Arisawa

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
