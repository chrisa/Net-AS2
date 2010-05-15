use strict;
use Test::More qw/ no_plan /;
use Net::AS2;
use File::Slurp qw/ read_file /;
use Data::Dumper;
use LWP::UserAgent;

my $our_key = read_file('t/babel_us-key.pem');
my $our_cert = read_file('t/babel_us-cert.pem');
my $their_cert = read_file('t/babel_them-cert.pem');

my $as2 = Net::AS2->new(
	uri  => 'http://babelas2.babelabout.net/',
	from => 'BabelAS2 Test Client',
);
ok($as2);
$as2->add_key(  'BabelAS2 Test Client' => $our_key );
$as2->add_cert( 'BabelAS2 Test Client' => $our_cert );
$as2->add_cert( 'BabelAS2 Test Server' => $their_cert );

my $payload = 'this is the payload';
my $content_type = 'text/plain';

my $req = $as2->request(
	to           => 'BabelAS2 Test Server',
	signed       => 'BabelAS2 Test Client',
	encrypted    => 'BabelAS2 Test Server',
	payload      => $payload,
	content_type => $content_type,
);
ok($req);

$req->prepare_body;
$req->prepare_http;

#diag($req->as_string);

#my $ua = LWP::UserAgent->new;
#my $response = $ua->request($req->http);
#diag(Dumper($response));
