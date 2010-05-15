use strict;
use Test::More tests => 18;
use Test::Moose;

BEGIN { use_ok 'Net::AS2' };
use File::Slurp qw/ read_file /;

my $our_key = read_file('t/our.identity-key.pem');
my $our_cert = read_file('t/our.identity-cert.pem');
my $their_cert = read_file('t/their.identity-cert.pem');

my $as2 = Net::AS2->new(
	uri  => 'http://localhost:80/as2',
	from => 'our.identity@example.com',
);
ok($as2);
$as2->add_key( 'our.identity@example.com' => $our_key );
$as2->add_cert( 'our.identity@example.com' => $our_cert );
$as2->add_cert( 'their.identity@example.com' => $their_cert );

my $payload = 'this is the payload';
my $content_type = 'text/plain';

my $req = $as2->request(
	to           => 'their.identity@example.com',
	payload      => $payload,
	content_type => $content_type,
);
ok($req);
isa_ok($req, 'Net::AS2::Request');
meta_ok($req);
$req->prepare_body;
$req->prepare_http;
#my $message = $req->as_string;
#diag("\n", $message);
#ok($message);

my $req_signed = $as2->request(
	to           => 'their.identity@example.com',
	signed       => 'our.identity@example.com',
	payload      => $payload,
	content_type => $content_type,
);
ok($req_signed);
isa_ok($req_signed, 'Net::AS2::Request');
meta_ok($req_signed);
does_ok($req_signed, 'Net::AS2::Request::Role::Signed');

my $req_encrypted = $as2->request(
	to           => 'their.identity@example.com',
	encrypted    => 'their.identity@example.com',
	payload      => $payload,
	content_type => $content_type,
);
ok($req_encrypted);
isa_ok($req_encrypted, 'Net::AS2::Request');
meta_ok($req_encrypted);
does_ok($req_encrypted, 'Net::AS2::Request::Role::Encrypted');

my $req_signed_encrypted = $as2->request(
	to           => 'their.identity@example.com',
	signed       => 'our.identity@example.com',
	encrypted    => 'their.identity@example.com',
	payload      => $payload,
	content_type => $content_type,
);
ok($req_signed_encrypted);
isa_ok($req_signed_encrypted, 'Net::AS2::Request');
meta_ok($req_signed_encrypted);
does_ok($req_signed_encrypted, 'Net::AS2::Request::Role::Signed');
does_ok($req_signed_encrypted, 'Net::AS2::Request::Role::Encrypted');