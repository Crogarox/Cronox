use strict;
use warnings;
use Test::More;
use FindBin;
use Cwd ();

BEGIN { use_ok 'Cronox::Util' }

ok path_to('log'), 'relative path';
is path_to('/path/to') => '/path/to', 'abstruct dir path';
is path_to(path_to('t/data/conf/configloader.yml'))
    => sprintf('%s/%s', Cronox::Util->home, 't/data/conf/configloader.yml'),
    'abstruct file path';

is script_name([ qw(t/bin/echo.sh --option hoge) ])
    => 'echo.sh', 'script_name(relative)';

is script_name([ "$ENV{PWD}/t/bin/echo.sh", qw(--option hoge) ])
    => 'echo.sh', 'script_name(abstract)';

is script_path([ qw(bin/cronox --option hoge) ])
    => Cwd::abs_path("$ENV{PWD}/bin"), 'script_path(relative)';

is script_path([ "$ENV{PWD}/bin/cronox", qw(--option hoge) ])
    => Cwd::abs_path("$ENV{PWD}/bin"), 'script_path(abstract)';

is parse_command([ qw(/bin/ls -l -- /path/to) ])
    => "/bin/ls", 'parse_command(array)';

is parse_command([ "/bin/ls -l -- /path/to" ])
    => "/bin/ls", 'parse_command(string)';

is parse_script_name([ "/bin/ls -l -- /path/to" ])
    => "ls", 'parse_script_name';

done_testing;
