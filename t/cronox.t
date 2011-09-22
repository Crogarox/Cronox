use strict;
use warnings;
use Test::More;
use t::TestCronox;
use Cronox::Util;
use Data::Dumper;

BEGIN { use_ok 'Cronox' }

subtest 'Load and call plugins' => sub {
    my $opts = { config_file => path_to('t/data/conf/load_plugin.yaml') };
    my $plugin_opts = [];

    my $cx = Cronox->new([ 'ls' ], $opts, $plugin_opts);
    $cx->load_plugins;

    for my $method (trigger_methods()) {
        $cx->call_trigger($method);
        is_deeply(@{ $cx->last_trigger_results }, [$method], "call $method");
    }
    done_testing;
};

subtest 'Load plugin options' => sub {
    my $opts = { config_file => path_to('t/data/conf/load_plugin_options.yaml') };

    my $tests = [
        {
            plugin_opts => [],
            expected => {},
        },
        {
            plugin_opts => [
                qw(t_testcronox_pluginoptions:key:value
                   t_testcronox_pluginoptions:hom:hum
                   t_testcronox_pluginoptions_cannotload:key:value)
            ],
            expected => {
                key => 'value',
                hom => 'hum',
            },
        },
    ];

    for my $test (@$tests) {
        my $cx = Cronox->new([ 'ls' ], $opts, $test->{plugin_opts});
        $cx->load_plugins;
        $cx->call_trigger('init');
        is_deeply(@{ $cx->last_trigger_results }, [ $test->{expected} ]);
    }
    done_testing;
};

{
    note 'Execute commands';
    my $opts = { config_file => path_to('t/data/conf/load_plugin.yaml') };
    my $plugin_opts = [];

    my $tests = [
        {
            command   => [qw(ls /path/is/not/found)],
            output    => "ls: /path/is/not/found:",
            exit_code => 2,
        },
        {
            command   => [qw(echo -n cronox test)],
            output    => "cronox test",
            exit_code => 0,
        },
    ];

    for my $test (@$tests) {
        my $cx = Cronox->new($test->{command}, $opts, $plugin_opts)->run;
        like( $cx->output, qr/^$test->{output}/,
            sprintf( 'fixed "%s" output', show_cmd( $test->{command} ) ) );
        is( $cx->exit_code, $test->{exit_code},
            sprintf( 'fixed "%s" output', show_cmd( $test->{command} ) ) );
    }
};

done_testing;
