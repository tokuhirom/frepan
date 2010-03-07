use inc::Module::Install;
all_from "lib/FrePAN.pm";

tests 't/*.t t/*/*.t t/*/*/*.t';
requires 'AnyEvent::FriendFeed::Realtime';
requires 'AnyEvent::Watchdog';
requires 'AE';
requires 'Amon';
requires 'AnyEvent::Gearman::Client';
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
recursive_author_tests('xt');

WriteAll;
