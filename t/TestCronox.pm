package t::TestCronox;
use strict;
use warnings;
use Data::Dumper;
use Cronox;
use Cronox::Plugin;
use Test::More;
use Test::mysqld;

our @EXPORT = qw(context show_cmd clean_log d
                 test_db_config create_test_db
                 trigger_methods can_trigger_methods);
use base qw(Exporter);

our $context;
our $mysqld;

sub context {
    my $cmd = shift;
    $context = Cronox->new($cmd || [qw(ls)],
                           { config_file => './t/data/conf/test_all.yaml' }, {});
    $context;
}

sub show_cmd {
    my $cmd = shift;
    my $command = $cmd ? $cmd : $context ? $context->cmd : [];
    join ' ', @$command;
}

sub clean_log {
    my $file = shift;
    unlink $file if -e $file;
}

sub d { warn Dumper(shift) }

sub test_db_config {
    $mysqld = Test::mysqld->new(
        my_cnf => {
            'skip-networking' => '',
        }
    ) or plan skip_all => $Test::mysqld::errstr;

    return {
        driver   => 'mysql',
        dsn      => $mysqld->dsn(),
        username => 'root',
        password => "",
        attrs => {
            AutoCommit => 0,
            RaiseError => 1,
        }
    };
}

sub create_test_db {
    my $dbh = shift;

    open my $fh, '<', './conf/cronox.sql';
    my $sql = do { local $/; <$fh> };
    close $fh;
    $dbh->do($sql);
}


sub trigger_methods { @Cronox::Plugin::TRIGGER_METHODS }

sub can_trigger_methods {
    my $plugin = shift;
    ok $plugin->can($_), "can $_" for trigger_methods();
}

1;
