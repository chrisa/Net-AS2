package Net::AS2::Request::Role::Signed;
use strict;
use warnings;
use Moose::Role;
use MIME::Parser;

sub setPrivateKey {
	my ($self, $key, $cert) = @_;
	$self->smime->setPrivateKey($key, $cert); # XXX passphrase
}

after 'prepare_body' => sub {
	my ($self) = @_;
	my $signed = $self->smime->sign($self->body->as_string);
	my $parser = MIME::Parser->new;
	$parser->tmp_to_core(1);
	$parser->output_to_core(1);
	my $entity = $parser->parse_data($signed);
	$self->_set_body($entity);
};

1;
