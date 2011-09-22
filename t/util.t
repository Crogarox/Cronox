use strict;
use warnings;
use Test::More;
use FindBin;

BEGIN { use_ok 'Cronox::Util' }

ok path_to('log'), 'relative path';
is path_to('/path/to') => '/path/to', 'abstruct dir path';
is path_to(path_to('t/data/conf/configloader.yml'))
    => sprintf('%s/%s', Cronox::Util->home, 't/data/conf/configloader.yml'),
    'abstruct file path';

is script_name([ qw(t/bin/echo.sh --option hoge) ])
    => 'echo.sh', 'script_name';

is script_path([ qw(bin/cronox --option hoge) ])
    => "$ENV{PWD}/bin", 'script_name';

is parse_command([ qw(ls -l -- /path/to) ])
    => "ls", 'script_name';

done_testing;
