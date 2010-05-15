package Net::AS2;
use Moose;
use MooseX::Types::Moose qw/ HashRef Str /;

use MIME::Lite;
use Crypt::SMIME;
use HTTP::Request;

use Net::AS2::Request;
use Net::AS2::Request::Role::Signed;
use Net::AS2::Request::Role::Encrypted;

use Net::AS2::Types qw/ CertPEM KeyPEM /;

use 5.008;
our $VERSION = '0.0.1';

=head1 NAME

Net::AS2 - Support for RFC4130 "AS2" Messages

=head1 DESCRIPTION

=cut

has 'keys' => (
	traits  => ['Hash'],
	is      => 'ro',
	isa     => HashRef[KeyPEM],
	default => sub { {} },
	handles => {
		add_key => 'set',
		get_key => 'get',
	}
);

has 'certs' => (
	traits  => ['Hash'],
	is      => 'ro',
	isa     => HashRef[CertPEM],
	default => sub { {} },
	handles => {
		add_cert => 'set',
		get_cert => 'get',
	}
);

has 'uri'  => (is => 'ro', isa => Str, required => 1);
has 'from' => (is => 'ro', isa => Str, required => 1);
	
sub request {
	my ($self, %params) = @_;
	
	my $body;
	if ($params{signed} || $params{encrypted}) {
		$body = Crypt::SMIME->new;
		if ($params{signed}) {
			$body->setPrivateKey(
				$self->get_key($params{signed}),
				$self->get_cert($params{signed}),
				# XXX passphrase
			);
		}
		if ($params{encrypted}) {
			$body->setPublicKey(
				$self->get_cert($params{encrypted}),
			);
		}
	}
	else {
		$body = MIME::Lite->new;
	}

	my $http = HTTP::Request->new;

	my $request = Net::AS2::Request->new(
		from    => $self->from,
		to      => $params{to},
		body    => $body,
		http    => $http,
		uri     => $self->uri,
		payload => $params{payload},
	);
	if ($params{signed}) {
		Net::AS2::Request::Role::Signed->meta->apply($request);
	}
	if ($params{encrypted}) {
		Net::AS2::Request::Role::Encrypted->meta->apply($request);
	}		

	return $request;
}

=head1 LICENCE

BSD

=head1 AUTHOR

Chris Andrews <chris@nodnol.org>

=cut

__PACKAGE__->meta->make_immutable;
