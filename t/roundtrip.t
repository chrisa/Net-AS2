use strict;
use Test::More qw/ no_plan /;
use Test::Moose;
use Data::Dumper;

BEGIN { use_ok 'Net::AS2' };
use File::Slurp qw/ read_file /;

my $our_key    = read_file('t/our.identity-key.pem');
my $our_cert   = read_file('t/our.identity-cert.pem');
my $their_cert = read_file('t/their.identity-cert.pem');
my $their_key  = read_file('t/their.identity-key.pem');

my $send_as2 = Net::AS2->new(
	uri  => 'http://localhost:80/as2',
	from => 'our.identity@example.com',
);
ok($send_as2);
$send_as2->add_key(  'our.identity@example.com' => $our_key );
$send_as2->add_cert( 'our.identity@example.com' => $our_cert );
$send_as2->add_key(  'their.identity@example.com' => $their_key );
$send_as2->add_cert( 'their.identity@example.com' => $their_cert );

my $payload = 'this is the payload';
my $content_type = 'text/plain';

my $req = $send_as2->create_request(
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
$req->prepare_body;
$req->prepare_http;

my $message = $req->as_string;
#diag("\n", $message);
ok($message);
like($message, qr/Content-Type: application\/pkcs7-mime/);
like($message, qr/Content-Disposition: attachment/);
like($message, qr/Content-Transfer-Encoding: base64/);

my $recv_as2 = Net::AS2->new(	
	uri  => 'http://localhost:80/as2',
	from => 'their.identity@example.com',
);
ok($recv_as2);
$recv_as2->add_key(  'their.identity@example.com' => $their_key );
$recv_as2->add_cert( 'their.identity@example.com' => $their_cert );
$recv_as2->add_key(  'our.identity@example.com' => $our_key );
$recv_as2->add_cert( 'our.identity@example.com' => $our_cert );

$payload = $recv_as2->handle_request($req->http);
ok($payload);
#diag(Dumper($payload));
