use strict;
use warnings;
use Test::More;
use t::TestCronox;

BEGIN { use_ok 'Cronox::Plugin::Notify::Mail' }

can_trigger_methods('Cronox::Plugin::Notify::Mail');

done_testing;
