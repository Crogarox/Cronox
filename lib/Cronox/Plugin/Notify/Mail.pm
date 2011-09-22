package Cronox::Plugin::Notify::Mail;
use strict;
use warnings;
use base qw(Cronox::Plugin);
use Encode qw(is_utf8 decode_utf8 encode);
use Email::MIME;
use Email::MIME::Creator;
use Email::Send qw();
use Cronox::Util;

sub finalize {
    my ($self, $cx) = @_;

    my $notify_status = $self->{opts}{notify_status}
                     || $self->config->{notify_status};

    return if ($notify_status eq 'error' && $cx->exit_code eq 0);

    my $config = $self->config;
    my $prefix = ($cx->exit_code eq 0) ? "" : '[error]';

    my $subject = sprintf( '%s%s: %s', $prefix, 'cronox', $cx->cmdstr );
    my $body = $self->set_body($cx);
    my $subject_encoding = 'MIME-Header-ISO_2022_JP';

    my $email = Email::MIME->create(
        header => [
            From    => $config->{from},
            Subject => is_utf8($subject)
                ? encode( $subject_encoding, $subject )
                : encode( $subject_encoding, decode_utf8($subject) )
        ],
        attributes => {
            charset  => 'ISO-2022-JP',
            encoding => '7bit',
        },
        body_str => is_utf8($body) ? $body : decode_utf8($body)
    );

    my $args = $config->{smtp}
      ? {
        mailer      => 'SMTP',
        mailer_args => [ Host => $config->{smtp} ],
      }
      : { mailer => 'sendmail', };

    my $sender = Email::Send->new($args);
    my $mail_to = $self->{opts}->{to} ? [ $self->{opts}->{to} ] : $config->{to};
    for my $to ( @$mail_to ) {
        $email->header_set( To => $to );
        eval {
            my $rv = $sender->send($email);
            $cx->diag("$rv: $to");
        };
        if (my $e = $@) {
            $cx->diag("caught error: $e");
        };
    }
}

sub set_body {
    my ($self, $cx) = @_;

    return sprintf( "[%s]\nhost:%s\ncmd:%s\nexit_code:%s\n%s",
                    now(), $cx->{host}, $cx->cmdstr, $cx->exit_code, $cx->output );
}

1;
