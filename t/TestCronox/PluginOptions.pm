package t::TestCronox::PluginOptions;
use strict;
use warnings;
use base qw(Cronox::Plugin);

sub init {
    my ($self, $c) = @_;
    return $self->{opts};
}

1;
