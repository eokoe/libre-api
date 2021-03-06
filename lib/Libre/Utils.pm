package Libre::Utils;
use common::sense;

=encoding UTF-8

=head1 NAME

Libre::Utils

=cut

use Crypt::PRNG qw(random_string);
use Data::Section::Simple qw(get_data_section);

use vars qw(@ISA @EXPORT);

@ISA    = (qw(Exporter));
@EXPORT = qw(is_test random_string get_data_section get_libre_api_url_for truncate_money get_libre_httpcb_url_for);

=head1 METHODS

=head2 is_test()

Retorna 1 caso esteja rodando em uma suíte de testes.

=cut

sub is_test {
    if ($ENV{HARNESS_ACTIVE} || $0 =~ m{forkprove}) {
        return 1;
    }
    return 0;
}

sub get_libre_api_url_for {
    my $args = shift;

    $args = "/$args" unless $args =~ m{^\/};
    my $libre_url = $ENV{LIBRE_URL};
    $libre_url =~ s/\/$//;

    return ( ( is_test() ? "http://localhost" : $libre_url ) . $args );
}

sub get_libre_httpcb_url_for {
    my $args = shift;

    $args = "/$args" unless $args =~ m{^\/};
    my $libre_httpcb_url = $ENV{LIBRE_HTTP_CB_URL};
    $libre_httpcb_url =~ s/\/$//;

    return ( ( is_test() ? "http://localhost" : $libre_httpcb_url ) . $args );
}

sub truncate_money {
    my $number = shift;

    if (!defined($number) || $number < 0) {
        die "invalid number";
    }

    return int($number * 100) / 100;
}

=head1 AUTHOR

Junior Moraes L<juniorfvox@gmail.com|mailto:juniorfvox@gmail.com>.

=cut

1;
