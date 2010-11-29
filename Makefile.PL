use inc::Module::Install;
all_from "lib/FrePAN.pm";

use lib 'extlib/lib/perl5/';

tests 't/*.t t/*/*.t t/*/*/*.t';
requires 'Amon2' => 2.04;
requires 'JSON::XS';
requires 'URI';
requires 'LWP::UserAgent';
requires 'Archive::Extract';
requires 'Guard';
requires 'Path::Class';
requires 'autodie';
requires 'Pod::POM' => 0.27;
requires 'parent';
requires 'Gravatar::URL';
requires 'XML::Feed';
requires 'XML::Feed::Deduper';
requires 'Algorithm::Diff';
requires 'Class::Accessor::Fast';
requires 'CPAN::DistnameInfo'; # parse path name
requires 'Archive::Zip';
requires 'Cache::Memcached::Fast' => 0.19;
requires 'RPC::XML';
requires 'Log::Minimal';
requires 'Smart::Args';
recursive_author_tests('xt');

WriteAll;
