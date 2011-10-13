package Cronox::ConfigLoader;

use strict;
use warnings;
use Carp ();
use YAML::Syck;
use Cronox::Util;
use Class::Accessor::Lite ( rw => [qw(config config_file opts)] );

sub new {
    my $class = shift;

    my %args = !@_ ? () : ( @_ && ref $_[0] eq 'HASH' ) ? %{ $_[0] } : @_;

    Carp::croak('Specify either dualboot and nodualboot options')
      if $args{dualboot} && $args{nodualboot};

    return bless {
        opts        => \%args,
        config      => {},
        config_file => find_config(%args),
    }, $class;
}

sub find_config {
    my %args = @_;
    my $config_file = $args{config} && -f path_to("conf/$args{config}") && path_to("conf/$args{config}")
                   || $args{config}
                   || path_to("conf/cronox.yaml");
    $config_file .= ".$args{env}" if $args{env};

    -f $config_file || die "$config_file is not found";
    $config_file;
}

sub load {
    my $self = shift;

    return $self->config if keys %{ $self->config };
    my $config = YAML::Syck::LoadFile( $self->config_file );

    my $opts = $self->opts;

    $config->{can_dualboot} =
        ( $opts->{dualboot}   ||  $config->{dualboot} ) ? 1
      : ( $opts->{nodualboot} || !$config->{dualboot} ) ? 0
      :                                                   0; # default

    $self->config($config);
    $self;
}

1;
