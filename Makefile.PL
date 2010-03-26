use inc::Module::Install;
all_from "lib/FrePAN.pm";

tests 't/*.t t/*/*.t t/*/*/*.t';
requires 'Amon' => 0.22;
requires 'Perl6::Say';
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
requires 'Algorithm::Diff';
requires 'Log::Dispatch::Screen::Color' => 0.03;
requires 'TheSchwartz';
requires 'TheSchwartz::Simple';
requires 'Class::Accessor::Fast';
requires 'CPAN::DistnameInfo';
requires 'Data::Page';
recursive_author_tests('xt');

WriteAll;
