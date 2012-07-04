package Cronox::Config;

use Config::ENV 'CRONOX_ENV';

my ($config, $config_local) = (undef, undef);
if (-f $ENV{CRONOX_CONFIG}) {
    $config = load($ENV{CRONOX_CONFIG});
}
if (-f $ENV{CRONOX_LOCAL_CONFIG}) {
    $config_local = load($ENV{CRONOX_LOCAL_CONFIG});
}

common +{
    tmpdir => '/tmp/cronox',
    lock => 1,
    print_stderr => 1,

    plugins => [
        {
            module => 'Recorder::Log',
            disable => 0,
            config => {
                dir => 'log',
                filename => undef,
                retention_days => 7,
            },
        },
        {
            module => 'Recorder::Database',
            disable => 0,
            config => {
                driver   => 'mysql',     # Fixed value. It's hard coding...
                hostname => 'localhost',
                database => 'cronox',
                username => 'cronox',
                password => 'cronox',
            },
        },
        {
            module => 'Notify::Mail',
            disable => 0,
            config => {
                notify_status => 'error',
                smtp => 'smtp.example.com',
                from => 'cronox@example.com',
                to => [ qw/arisawa+cronox@gmail.com/ ],
            },
        },
    ],

    %$config,
    %$config_local,
};

config 'local' => +{
    dualboot => 1,

    'Recorder::Database::config::password' => 'local_password',

    'Notify::Mail::config::smtp' => 'local.smtp.example.com',
    'Notify::Mail::config::to'   => [ qw/arisawa+debug@gmail.com/ ],
};

1;
