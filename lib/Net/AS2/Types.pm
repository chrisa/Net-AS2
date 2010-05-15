package Net::AS2::Types;
use strict;
use warnings;
use MooseX::Types::Moose qw/ Str /;
use MooseX::Types -declare => [qw/ CertPEM KeyPEM HttpReq SMIME MIME /];

subtype CertPEM,
     as Str,
     where { /^-----BEGIN CERTIFICATE-----/ };

subtype KeyPEM,
     as Str,
     where { /^-----BEGIN RSA PRIVATE KEY-----/ };

class_type HttpReq, { class => 'HTTP::Request' };

class_type SMIME, { class => 'Crypt::SMIME' };

class_type MIME, { class => 'MIME::Entity' };

1;
