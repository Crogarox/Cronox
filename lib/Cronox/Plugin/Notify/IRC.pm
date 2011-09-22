package Cronox::Plugin::Notify::IRC;
use strict;
use warnings;
use base qw(Cronox::Plugin);
use Cronox::Util;

# とちゅうです
# 正直そんなにいらないんじゃないかと思う
# 通知のためにextlib作ってモジュールいれたりするのめんどい

sub finalize {
    my ($self, $c) = @_;

    return
      if $self->config->{notify_status} eq 'error' && !$c->exit_code;

    my $config = $self->config;
    my $prefix = $c->exit_code ? '[error]' : "";
    my $script = script_path( $c->cmd ).'/'.script_name( $c->cmd );
}

sub new {
    my ($class, %args) = @_;
}


1;

__END__

=head1 NAME

B<Cronox::Plugin::Notify::IRC> - 

=head1 VERSION

0.01

=head1 SYNOPSIS

=head1 DESCRIPTION

Cronox::Plugin::Notify::IRC is 

=head1 AUTHOR

Kosuke Arisawa

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
