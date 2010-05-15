package Net::AS2::Request::Role::Encrypted;
use strict;
use warnings;
use Moose::Role;
use MIME::Parser;

sub setPublicKey {
	my ($self, $cert) = @_;
	$self->smime->setPublicKey($cert);
}

after 'prepare_body' => sub {
	my ($self) = @_;
	my $encrypted = $self->smime->encrypt($self->body->as_string);
	my $parser = MIME::Parser->new;
	$parser->tmp_to_core(1);
	$parser->output_to_core(1);
	my $entity = $parser->parse_data($encrypted);
	$self->_set_body($entity);
};

1;
