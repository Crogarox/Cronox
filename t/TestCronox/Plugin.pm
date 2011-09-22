package t::TestCronox::Plugin;
use strict;
use warnings;
use base qw(Cronox::Plugin);

sub init     { 'init' }
sub readline { 'readline' }
sub finalize { 'finalize' }
sub error    { 'error' }

1;
