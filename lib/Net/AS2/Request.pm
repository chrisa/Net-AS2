package Net::AS2::Request;
use Moose;
use MooseX::Types::Moose qw/ Str /;
use MooseX::Types::URI qw/ Uri /;
use Net::AS2::Types qw/ HttpReq SMIME MIME /;
use Email::MessageID;
use HTTP::Date;
use Crypt::SMIME;

=head1 NAME

Net::AS2 - Request class for RFC4130 "AS2" Messages

=head1 DESCRIPTION

=cut

has 'http'    => (is => 'ro', isa => HttpReq, required => 1);
has 'body'    => (is => 'ro', isa => MIME,    required => 1, writer => '_set_body');
has 'smime'   => (is => 'ro', isa => SMIME,   lazy => 1, default => sub { Crypt::SMIME->new } );

has 'payload' => (is => 'rw', isa => Str, required => 0);
has 'uri'     => (is => 'rw', isa => Uri, required => 1, coerce => 1);

has 'to'       => (is => 'rw', isa => Str, required => 1);
has 'from'     => (is => 'rw', isa => Str, required => 1);
has 'as2_to'   => (is => 'rw', isa => Str, required => 0);
has 'as2_from' => (is => 'rw', isa => Str, required => 0);

has 'subject'      => (is => 'rw', isa => Str, required => 0, default => 'AS2 Message');
has 'content_type' => (is => 'rw', isa => Str, required => 0, default => 'text/plain');

sub BUILD {
	my ($self) = @_;

	if (!defined $self->as2_to) {
		$self->as2_to($self->to);
	}
	if (!defined $self->as2_from) {
		$self->as2_from($self->from);
	}
}

sub prepare_body {
	my ($self) = @_;

	$self->body->build(
		Type => $self->content_type,
		Data => $self->payload,
	);
}

sub prepare_http {
	my ($self) = @_;

	$self->http->header( 'Host'       => $self->uri->host );
	$self->http->header( 'Connection' => 'close' );
	$self->http->header( 'Date'       => time2str() );
	$self->http->header( 'Accept'     => '*/*' );

	$self->http->header( 'User-Agent'   => 'Perl Net::AS2' );
	$self->http->header( 'AS2-Version'  => '1.0' );
	$self->http->header( 'MIME-Version' => '1.0' );

	$self->http->header( 'To'	=> $self->to );
	$self->http->header( 'From'	=> $self->from );
	$self->http->header( 'AS2-To'	=> $self->as2_to );
	$self->http->header( 'AS2-From' => $self->as2_from );
	$self->http->header( 'Subject'  => $self->subject );

	my $message_id = Email::MessageID->new;
	$self->http->header( 'Message-ID' => "<$message_id>" );

	for my $header ($self->body->head->tags) {
		$self->http->header( $header => $self->body->head->get($header) );
	}

	$self->body->head->replace('Content-Transfer-Encoding', 'binary');
	{
		use bytes;
		my $content = $self->body->body_as_string;
		$self->http->header( 'Content-Length' => length $content );
		$self->http->content($content);
	}
}

sub handle_body {
	my ($self) = @_;

}

sub as_string {
	my ($self) = @_;
	return $self->http->as_string;
}

__PACKAGE__->meta->make_immutable;
