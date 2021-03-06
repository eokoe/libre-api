package Libre::Schema::ResultSet::Journalist;
use common::sense;
use Moose;
use namespace::autoclean;

extends 'DBIx::Class::ResultSet';

# Verificar roles
with 'Libre::Role::Verification';
with 'Libre::Role::Verification::TransactionalActions::DBIC';

# use Business::BR::CEP qw(teste_cep);
use Libre::Types qw(CPF CNPJ EmailAddress PhoneNumber);

use Data::Verifier;

sub verifiers_specs {
    my $self = shift;

    return {
        create => Data::Verifier->new(
            filters => [ qw(trim) ],
            profile => {
                email   => {
                    required    => 1,
                    type        => EmailAddress,
                    filters     => [ qw(lower) ],
                    post_check  => sub {
                        my $r = shift;

                        $self->result_source->schema->resultset('User')->search({
                            email => $r->get_value('email'),
                        })->count and die \["email", "alredy exists"];

                        return 1;
                    }
                },
                password => {
                    required => 1,
                    type     => 'Str',
                },
                name => {
                    required => 1,
                    type     => "Str",
                },
                surname => {
                    required => 0,
                    type     => "Str",
                },
                cpf => {
                    required    => 0,
                    type        => CPF,
                    post_check  => sub {
                        my $r = shift;

                        $self->search({
                            cpf => $r->get_value('cpf'),
                        })->count and die \["cpf", "alredy exists"];

                        return 1;
                    },
                },
                cnpj => {
                    required => 0,
                    type     => CNPJ,
                    post_check  => sub {
                        my $r = shift;

                        $self->search({
                            cnpj => $r->get_value('cnpj'),
                        })->count and die \["cnpj", "alredy exists"];

                        return 1;
                    },
                },
                address_state => {
                    required   => 1,
                    type       => 'Str',
                    post_check => sub {
                        my $r = shift;

                        my $state = $r->get_value('address_state');
                        $self->result_source->schema->resultset('State')->search({ name => $state })->count;
                    },
                },
                address_city => {
                    required   => 1,
                    type       => 'Str',
                    post_check => sub {
                        my $r = shift;

                        my $city = $r->get_value('address_city');
                        $self->result_source->schema->resultset('City')->search({ name => $city })->count;
                    },
                },
                address_zipcode => {
                    required   => 1,
                    type       => 'Str',
                    post_check => sub {
                        my $r = shift;

                        my $cep = $r->get_value('address_zipcode');

                        # return test_cep($cep);
                        return $cep;
                    },
                },
                address_street => {
                    required   => 1,
                    type       => 'Str',
                },
                address_residence_number => {
                    required   => 1,
                    type       => 'Int',
                },
                address_complement => {
                    required   => 0,
                    type       => 'Str',
                },
                cellphone_number => {
                    required   => 1,
                    type       => PhoneNumber,
                },
                vehicle      => {
                    required => 1,
                    type     => "Bool",
                },
                responsible_name => {
                    required => 0,
                    type     => 'Str',
                },
                responsible_surname => {
                    required   => 0,
                    type       => "Str",
                },
                responsible_cpf => {
                    required => 0,
                    type     => CPF,
                },
            },
        ),
    };
}

sub action_specs {
    my ($self) = @_;

    return {
        create => sub {
            my $r = shift;

            my %values = $r->valid_values;
            not defined $values{$_} and delete $values{$_} for keys %values;

            if (((!$values{cpf} && !$values{cnpj}) || ($values{cpf} && $values{cnpj})) && $values{vehicle}) {
                die \["cpf", "Must have either CPF or CNPJ"];
            }

            # use DDP; p $values{cpf};
            # if ((!$values{cpf} && !$values{cnpj}) && (!defined(length $values{cpf}) || length $values{cpf} < 10)) {
            #     die \["cpf", "must have 11 numbers"];
            # }

            # if ((!$values{cnpj} && !$values{cnpj}) && (!defined(length $values{cnpj}) || length $values{cnpj} < 13)) {
            #     die \["cnpj", "must have 14 numbers"];
            # }

            if ($values{vehicle} && $values{cpf}) {
                die \["cpf", "not allowed"];
            }

            if (!$values{vehicle} && !$values{surname}) {
                die \["surname", "Journalist must have a surname"];
            }

            if ($values{vehicle} && !$values{responsible_cpf}) {
                die \["responsible_cpf", "must have a responsible"];
            }

            if ($values{vehicle} && !$values{cellphone_number}) {
                die \["cellphone_number", "must have a responsible"];
            }

            if ($values{vehicle} && $values{surname}) {
                die \["surname", "Vehicle must'nt have a surname"];
            }

            if (!$values{vehicle} && ($values{responsible_cpf} || $values{responsible_name} || $values{responsible_surname})) {
                die \["responsible_cpf", "must not have a responsible"];
            }

            if ($values{vehicle} && (!$values{responsible_cpf} || !$values{responsible_name} || !$values{responsible_surname})) {
                die \["responsible_cpf", "must have a responsible"];
            }

            if (length $values{password} < 6) {
                die \["password", "must have at least 6 characters"];
            }

            my $user = $self->result_source->schema->resultset("User")->create(
                {
                    ( map { $_ => $values{$_} } qw(name surname email password) ),
                    verified    => 1,
                    verified_at => \"now()",
                }
            );

            $user->add_to_roles({ id => 2 });

            # TODO adicionar envio de e-mail de confirmação de cadastro

            my $journalist = $self->create(
                {
                    (
                        map { $_ => $values{$_} } qw(
                            cpf cnpj address_state address_city address_zipcode address_street
                            address_residence_number vehicle cellphone_number responsible_name
                            responsible_surname responsible_cpf
                        )
                    ),
                    user_id => $user->id,
                }
            );

            return $journalist;
        },
    };
}

1;

