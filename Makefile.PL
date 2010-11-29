use inc::Module::Install;
all_from "lib/FrePAN.pm";

tests 't/*.t t/*/*.t t/*/*/*.t';
requires 'Amon' => 0.22;
requires 'JSON::XS';
requires 'URI';
requires 'LWP::UserAgent';
requires 'Archive::Extract';
requires 'Guard';
requires 'Path::Class';
requires 'autodie';
requires 'Pod::POM';
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
recursive_author_tests('xt');

WriteAll;
