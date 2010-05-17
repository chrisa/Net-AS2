package Net::AS2::Request::Role::Encrypted;
use strict;
use warnings;
use Moose::Role;
use MIME::Parser;

sub setPublicKey {
	my ($self, $cert) = @_;
	$self->smime->setPublicKey($cert);
}

sub setPrivateKey {
	my ($self, $key, $cert) = @_;
	$self->smime->setPrivateKey($key, $cert); # XXX passphrase
}

after 'prepare_body' => sub {
	my ($self) = @_;
	my $encrypted = $self->smime->encrypt($self->body->as_string);
	my $parser = MIME::Parser->new;
	$parser->decode_bodies(1);
	$parser->tmp_to_core(1);
	$parser->output_to_core(1);
	my $entity = $parser->parse_data($encrypted);
	$self->_set_body($entity);
};

before 'handle_body' => sub {
	my ($self, $as2) = @_;
	
	my $ciphertext = $self->body->as_string;
	my $decrypted = $self->smime->decrypt($ciphertext);
	my $parser = MIME::Parser->new;
	$parser->decode_bodies(0);
	$parser->tmp_to_core(1);
	$parser->output_to_core(1);
	my $entity = $parser->parse_data($decrypted);
	$self->_set_body($entity);
	
	if ($self->body->get('Content-Type') =~ /^multipart\/signed/) { # XXX
		Net::AS2::Request::Role::Signed->meta->apply($self);
		$self->setPublicKey(
			$as2->get_cert($self->from),
		);
	}
};
     
1;
