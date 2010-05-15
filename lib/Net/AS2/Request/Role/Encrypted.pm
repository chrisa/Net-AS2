package Net::AS2::Request::Role::Encrypted;
use strict;
use warnings;
use Moose::Role;

sub setPublicKey {
	my ($self, $cert) = @_;
	$self->smime->setPublicKey($cert);
}

1;
