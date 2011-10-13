use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use Path::Class;
use Cronox::Util;

BEGIN { use_ok 'Cronox::ConfigLoader' }

subtest 'find config' => sub {
    dies_ok { Cronox::ConfigLoader::find_config(config => '/not/found/config.yaml') };
    is Cronox::ConfigLoader::find_config(config => 'cronox.yaml', env => 'stage'),
        path_to('conf/cronox.yaml.stage'),
        'abbreviation of the config directory';
    is Cronox::ConfigLoader::find_config(config => "$FindBin::Bin/data/conf/configloader.yaml"),
        "$FindBin::Bin/data/conf/configloader.yaml",
        'abstract path';
    is Cronox::ConfigLoader::find_config(config => "t/data/conf/configloader.yaml"),
        "t/data/conf/configloader.yaml",
        'relative path';

    done_testing;
};

subtest 'Specified config file' => sub {
    my $config_file = "$FindBin::Bin/data/conf/configloader.yaml";
    my $c = Cronox::ConfigLoader->new(
        config => $config_file,
    )->load;

    is $config_file, $c->config_file, "config_file";
    ok $c->config->{cmd}{specified_file}, "read specified file config";
    done_testing;
};

subtest 'Specified dualboot on' => sub {
    my $c = Cronox::ConfigLoader->new( dualboot => 1 )->load;
    ok $c->config->{can_dualboot}, 'dualboot on';
    done_testing;
};

subtest 'Specified dualboot off' => sub {
    my $c = Cronox::ConfigLoader->new( nondualboot => 1 )->load;
    ok !$c->config->{can_dualboot}, 'dualboot off';
    done_testing;
};

subtest 'Specified dualboot on, off' => sub {
    dies_ok {
        Cronox::ConfigLoader->new(
            dualboot   => 1,
            nodualboot => 1,
        );
    };
    done_testing;
};

done_testing;
