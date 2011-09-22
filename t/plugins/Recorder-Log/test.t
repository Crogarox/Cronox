use strict;
use warnings;
use Test::More;
use Cronox::Util;
use t::TestCronox;

BEGIN { use_ok 'Cronox::Plugin::Recorder::Log' }

can_trigger_methods('Cronox::Plugin::Recorder::Log');

my $cx = context( [qw(t/bin/echo.sh)] );
my $ymd = now('ymd');
is ("/tmp/cronox.log.$ymd",
    Cronox::Plugin::Recorder::Log::_get_filename('/tmp', 'cronox'),
    'get filename',
);

subtest 'Specified relative directory, logfile, errfile' => sub {
    my $log = Cronox::Plugin::Recorder::Log->new(
        {
            dir     => 'log',
            logfile => 'test',
            errfile => 'err',
        },
    )->init($cx);

    is $log->logfile, path_to("log/test.log.$ymd"), 'logfile';
    is $log->errfile, path_to("log/err.log.$ymd"),  'errfile';
    done_testing;
};

subtest 'Specified abstract directory, logfile, errfile' => sub {
    my $log = Cronox::Plugin::Recorder::Log->new(
        {
            dir     => '/tmp',
            logfile => 'test',
            errfile => 'err',
        },
    )->init($cx);

    is $log->logfile, "/tmp/test.log.$ymd", 'logfile';
    is $log->errfile, "/tmp/err.log.$ymd",  'errfile';
    done_testing;
};

subtest 'Default logfile, errfile' => sub {
    my $log = Cronox::Plugin::Recorder::Log->new(
        {
            dir     => '/tmp',
        },
    )->init($cx);

    is $log->logfile, "/tmp/echo.sh.log.$ymd", 'logfile';
    is $log->errfile, "/tmp/cronox_err.log.$ymd",  'errfile';
    done_testing;
};

subtest 'logging' => sub {
    my $log = Cronox::Plugin::Recorder::Log->new(
        {
            dir     => '/tmp/cronox',
            logfile => 'test',
        },
    )->init($cx);

    clean_log($log->logfile);
    clean_log($log->errfile);

    my $normal = <<LOG;
debug
info
LOG
    my $error = <<LOG;
fatal
error
LOG
    $log->logging($normal);
    $log->logging($error, 'error');

    my ($fh, $result);
    open $fh, '<', $log->logfile;
    $result = do { local $/; <$fh> };
    close $fh;
    like($result, qr/$normal$/, 'normal log');

    open $fh, '<', $log->errfile;
    $result = do { local $/; <$fh> };
    close $fh;
    like($result, qr/$error$/, 'error log');

    done_testing;
};

subtest 'Remove Log' => sub {
    my $log = Cronox::Plugin::Recorder::Log->new(
        {
            dir     => '/tmp/cronox',
            logfile => 'test',
            opts    => [ qw(retension_days:2) ],
        },
    )->init($cx);

    $log->remove_log;
    ok 1;
    done_testing;
};

done_testing;
