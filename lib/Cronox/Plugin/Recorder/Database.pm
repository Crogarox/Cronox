package Cronox::Plugin::Recorder::Database;
use strict;
use warnings;
use Carp ();
use DBI;
use SQL::Maker;
use base qw(Cronox::Plugin);
use Cronox::Util;

sub init {
    my ($self, $cx) = @_;

    my $builder = SQL::Maker->new(driver => $self->config->{driver});
    my ($stmt, @bind) = $builder->insert(
        'history',
        {
            hostname => $cx->{host},
            script_name => script_name( $cx->cmd ),
            script_path => script_path( $cx->cmd ),
            command     => $cx->cmdstr,
            started_on  => time(),
        },
    );
    $self->{builder} = $builder;

    my $dbh = $self->dbh;
    my $sth = $dbh->prepare($stmt);
    $sth->execute(@bind);
    $self->{history_id} = $sth->{mysql_insertid};

    $dbh->commit     or Carp::croak $dbh->errstr;
    $dbh->disconnect or Carp::croak $dbh->errstr;
}

sub finalize {
    my ($self, $cx) = @_;

    my ($stmt, @bind) = $self->{builder}->update(
        'history',
        {
            exit_code   => $cx->exit_code,
            output      => $cx->output,
            finished_on => time(),
        },
        { id => $self->{history_id} },
    );

    my $dbh = $self->dbh;
    my $sth = $dbh->prepare($stmt);
    $sth->execute(@bind);

    $dbh->commit     or Carp::croak $dbh->errstr;
    $dbh->disconnect or Carp::croak $dbh->errstr;
}

sub dbh {
    my $self = shift;

    my $conf = $self->config;
    my $attrs = $conf->{attrs} || {
        AutoCommit => 0,
        RaiseError => 1,
    };

    my $connect_info = (defined $conf->{dsn})
        ? [ $conf->{dsn}, "", "", $attrs ]
        : [ sprintf("dbi:%s:database=%s;host=%s", @{$conf}{ qw/driver database hostname/ }),
            @{$conf}{ qw/username password/ },
            $attrs
        ];

    DBI->connect(@$connect_info) or die $DBI::errstr;
}

1;

__END__

=head1 NAME

B<Cronox::Plugin::Recorder::Database> - 

=head1 VERSION

0.01

=head1 SYNOPSIS

=head1 DESCRIPTION

Cronox::Plugin::Recorder::Database is 

=head1 AUTHOR

Kosuke Arisawa

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
