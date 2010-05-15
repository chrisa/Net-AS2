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
	
	#my ($prepared_mime, $outer_header) = 
	#     $self->smime->prepareSmimeMessage($self->body->as_string);
	#use Data::Dumper;
	#print STDERR Dumper { prep => $prepared_mime, outer => $outer_header };

	my $signed = $self->smime->sign($self->body->as_string);

	my $parser = MIME::Parser->new;
	my $entity = $parser->parse_data($signed);
};

1;
