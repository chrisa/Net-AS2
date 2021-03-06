package Net::AS2;
use Moose;
use MooseX::Types::Moose qw/ HashRef Str /;

use MIME::Entity;
use HTTP::Request;

use Net::AS2::Request;
use Net::AS2::Request::Role::Signed;
use Net::AS2::Request::Role::Encrypted;

use Net::AS2::Types qw/ CertPEM KeyPEM /;

use 5.008001;
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
	
sub create_request {
	my ($self, %params) = @_;
	
	my $body = MIME::Entity->new;
	my $http = HTTP::Request->new(POST => $self->uri);

	my $request = Net::AS2::Request->new(
		from	     => $self->from,
		to	     => $params{to},
		body	     => $body,
		http	     => $http,
		uri	     => $self->uri,
		payload	     => $params{payload},
		content_type => $params{content_type},
	);

	# Per RFC4130, sign then encrypt - order of role composition
	# is important.

	if ($params{signed}) {
		Net::AS2::Request::Role::Signed->meta->apply($request);
		$request->setPrivateKey(
			$self->get_key($params{signed}),
			$self->get_cert($params{signed}),
		);
	}
	if ($params{encrypted}) {
		Net::AS2::Request::Role::Encrypted->meta->apply($request);
		$request->setPublicKey(
			$self->get_cert($params{encrypted}),
		);
	}

	$request->prepare_body;
	$request->prepare_http;

	return $request;
}

sub handle_request {
	my ($self, $http) = @_;

	my $Encoding    = $http->header('Content-Transfer-Encoding');
	my $Type        = $http->header('Content-Type');
	my $Disposition = $http->header('Content-Disposition');

	chomp $Encoding;
	chomp $Type;
	chomp $Disposition;

	my %args = (
		Data	    => $http->content,
		Encoding    => $Encoding,
		Type	    => $Type,
		Disposition => $Disposition,
	);

	my $body = MIME::Entity->build(%args);
	$body->head->fold_length(1000);
	$body->head->unfold;

	my $request = Net::AS2::Request->new(
		from	     => $http->header('From'),
		to	     => $http->header('To'),
		as2_from     => $http->header('AS2-From'),
		as2_to       => $http->header('AS2-To'),
		subject      => $http->header('Subject'),
		http	     => $http,
		uri	     => $self->uri,
		body         => $body,
	);

	# XXX not necessarily to/from
	if ($http->header('Content-Type') =~ /^application\/pkcs7-mime/) {
		Net::AS2::Request::Role::Encrypted->meta->apply($request);
		$request->setPrivateKey(
			$self->get_key($request->to),
			$self->get_cert($request->to),
		);
	}

	$request->handle_body($self);
	
	return $request;
}

=head1 LICENCE

BSD

=head1 AUTHOR

Chris Andrews <chris@nodnol.org>

=cut

__PACKAGE__->meta->make_immutable;
