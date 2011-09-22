package Cronox::Plugin;
use strict;
use warnings;

our @TRIGGER_METHODS = qw(init readline finalize error);

sub new {
    my ($class, $config, $opts) = @_;

    bless {
        config => $config || {},
        opts   => _load_opts($opts),
    }, $class;
}

sub _load_opts {
    my $list_opts = shift;

    my $hash_opts = {};
    for my $opt (@$list_opts) {
        next unless $opt =~ /^([^:]+):([^:]+)/;
        $hash_opts->{$1} = $2;
    }
    $hash_opts;
}

sub config { shift->{config} }

sub register_hook {
    my ($self, $cx) = @_;

    for my $method (@TRIGGER_METHODS) {
        $cx->add_trigger(
            name      => $method,
            callback  => sub {
                my $cronox = shift;
                $self->$method($cronox, @_);
            },
        );
    }
}

sub init {
    my ($self, $cx) = @_;
}

sub readline {
    my ($self, $cx) = @_;
}

sub finalize {
    my ($self, $cx) = @_;
}

sub error {
    my ($self, $cx) = @_;
}

1;

__END__

=head1 NAME

B<Cronox::Plugin> - 

=head1 VERSION

0.01

=head1 SYNOPSIS

=head1 DESCRIPTION

Cronox::Plugin is 

=head1 AUTHOR

Kosuke Arisawa

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
