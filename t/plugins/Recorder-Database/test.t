use strict;
use warnings;
use Test::More;
use Cronox::Util;
use t::TestCronox;

BEGIN { use_ok 'Cronox::Plugin::Recorder::Database' }

can_trigger_methods('Cronox::Plugin::Recorder::Database');

# note 'create test database';
my $cx     = context();
my $config = test_db_config();
my $db     = Cronox::Plugin::Recorder::Database->new($config);
my $dbh    = $db->dbh; $dbh->{AutoCommit} = 1;
create_test_db($dbh);

{
    note 'Execute user script';
    $cx = context( [ './t/bin/echo.sh' ] );
    $db->init($cx);

    my $dbh = $db->dbh; $dbh->{AutoCommit} = 1;
    my $init = $dbh->selectrow_hashref('select * from history where id=?', { Slice => {} }, $db->{history_id} );
    is $init->{script_name}, 'echo.sh';
    is $init->{script_path}, Cronox::Util::home.'/t/bin';
    is $init->{exit_code}, 0;
    is $init->{command}, './t/bin/echo.sh';
    ok !$init->{output};
    ok $init->{started_on} > 0;
    ok $init->{finished_on} eq 0;

    $cx->exec;
    $db->finalize($cx);

    $dbh = $db->dbh; $dbh->{AutoCommit} = 1;
    my $finalize = $dbh->selectrow_hashref('select * from history where id=?', { Slice => {} }, $db->{history_id} );
    is $init->{$_}, $finalize->{$_}
        for qw(id script_name script_path exit_code command started_on);

    is $finalize->{output}, 'test';
    ok $finalize->{finished_on} > 0;

};

{
    note 'Execute user script error occured';
    $cx = context( [ './t/bin/echo_error.sh' ] );
    $db->init($cx);

    my $init = get_history($db);
    is $init->{script_name}, 'echo_error.sh';
    is $init->{script_path}, Cronox::Util::home.'/t/bin';
    is $init->{exit_code}, 0;
    is $init->{command}, './t/bin/echo_error.sh';
    ok !$init->{output};
    ok $init->{started_on} > 0;
    ok $init->{finished_on} eq 0;

    $cx->exec;
    $db->finalize($cx);

    my $finalize = get_history($db);
    is $init->{$_}, $finalize->{$_}
        for qw(id script_name script_path command started_on);

    ok $finalize->{exit_code} eq 1;
    is $finalize->{output}, 'test';
    ok $finalize->{finished_on} > 0;
};

{
    note 'Execute command';
    $cx = context( [ 'echo -n cronox' ] );
    $db->init($cx);

    my $init = get_history($db);
    is $init->{script_name}, "";
    is $init->{script_path}, "";
    is $init->{exit_code}, 0;
    is $init->{command}, 'echo -n cronox';
    ok !$init->{output};
    ok $init->{started_on} > 0;
    ok $init->{finished_on} eq 0;

    $cx->exec;
    $db->finalize($cx);

    my $finalize = get_history($db);
    is $init->{$_}, $finalize->{$_}
        for qw(id script_name script_path exit_code command started_on);

    is $finalize->{output}, 'cronox';
    ok $finalize->{finished_on} > 0;
};

sub get_history {
    my $db = shift;
    my $dbh = $db->dbh;
    $dbh->{AutoCommit} = 1;
    $dbh->selectrow_hashref('select * from history where id=?', { Slice => {} }, $db->{history_id} );
}

done_testing;
