use strict;
use Test::More qw/ no_plan /;
use Net::AS2;
use File::Slurp qw/ read_file /;
use Data::Dumper;
use LWP::UserAgent;

my $our_key = read_file('t/our.identity-key.pem');
my $our_cert = read_file('t/our.identity-cert.pem');
my $their_cert = read_file('t/their.identity-cert.pem');

my $as2 = Net::AS2->new(
	uri  => 'http://localhost:10080/',
	from => 'our.identity',
);
ok($as2);
$as2->add_key(  'our.identity' => $our_key );
$as2->add_cert( 'our.identity' => $our_cert );
$as2->add_cert( 'their.identity' => $their_cert );

my $payload = 'this is the payload';
my $content_type = 'text/plain';

my $req = $as2->create_request(
	to           => 'their.identity',
	signed       => 'our.identity',
	encrypted    => 'their.identity',
	payload      => $payload,
	content_type => $content_type,
);
ok($req);

$req->prepare_body;
$req->prepare_http;

my $ua = LWP::UserAgent->new;
my $response = $ua->request($req->http);
