use strict;
use Test::More tests => 37;
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

# CLEARTEXT, NOT SIGNED

my $req = $as2->create_request(
	to           => 'their.identity@example.com',
	payload      => $payload,
	content_type => $content_type,
);
ok($req);
isa_ok($req, 'Net::AS2::Request');
meta_ok($req);
my $message = $req->as_string;
#diag("\n", $message);
ok($message);
like($message, qr/^this is the payload/m);
like($message, qr/^Content-Type: text\/plain/m);
like($message, qr/^POST/m);
like($message, qr/^AS2-Version: 1.0/m);
like($message, qr/^MIME-Version: 1.0/m);

# CLEARTEXT, SIGNED

$req = $as2->create_request(
	to           => 'their.identity@example.com',
	signed       => 'our.identity@example.com',
	payload      => $payload,
	content_type => $content_type,
);
ok($req);
isa_ok($req, 'Net::AS2::Request');
meta_ok($req);
does_ok($req, 'Net::AS2::Request::Role::Signed');
$message = $req->as_string;
#diag("\n", $message);
ok($message);
like($message, qr/^this is the payload/m);
like($message, qr/^Content-Type: multipart\/signed/m);
like($message, qr/protocol="application\/pkcs7-signature"; micalg="sha1"/);
like($message, qr/Content-Type: application\/pkcs7-signature/);

# ENCRYPTED, NOT SIGNED

$req = $as2->create_request(
	to           => 'their.identity@example.com',
	encrypted    => 'their.identity@example.com',
	payload      => $payload,
	content_type => $content_type,
);
ok($req);
isa_ok($req, 'Net::AS2::Request');
meta_ok($req);
does_ok($req, 'Net::AS2::Request::Role::Encrypted');
$message = $req->as_string;
#diag("\n", $message);
ok($message);
like($message, qr/Content-Type: application\/pkcs7-mime/);
like($message, qr/Content-Disposition: attachment/);
like($message, qr/Content-Transfer-Encoding: base64/);

# ENCRYPTED, SIGNED

$req = $as2->create_request(
	to           => 'their.identity@example.com',
	signed       => 'our.identity@example.com',
	encrypted    => 'their.identity@example.com',
	payload      => $payload,
	content_type => $content_type,
);
ok($req);
isa_ok($req, 'Net::AS2::Request');
meta_ok($req);
does_ok($req, 'Net::AS2::Request::Role::Signed');
does_ok($req, 'Net::AS2::Request::Role::Encrypted');
$message = $req->as_string;
#diag("\n", $message);
ok($message);
like($message, qr/Content-Type: application\/pkcs7-mime/);
like($message, qr/Content-Disposition: attachment/);
like($message, qr/Content-Transfer-Encoding: base64/);

