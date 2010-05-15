use inc::Module::Install;

all_from 'lib/Net/AS2.pm';

requires 'Crypt::SMIME';
requires 'MIME::Parser';
requires 'HTTP::Request';
requires 'HTTP::Date';
requires 'Email::MessageID';
requires 'Moose';
requires 'MooseX::Types';
requires 'MooseX::Types::URI';

WriteAll;
