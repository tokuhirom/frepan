use strict;
use warnings;
use JSON::XS;
use LWP::UserAgent;
use FrePAN;
use FrePAN::DB;
use FrePAN::Worker;
use FrePAN::Worker::ProcessDist;

# my $json = '{"version":"2010.06501","url":"http://cpan.cpantesters.org/authors/id/C/CO/CORNELIUS/Vimana-2010.06501.tar.gz","name":"Vimana","path":"C/CO/CORNELIUS/Vimana-2010.06501.tar.gz"}';
my $json = '{"version":"1.100640","url":"http://search.cpan.org/CPAN/authors/id/J/JQ/JQUELIN/Dist-Zilla-Plugin-AutoPrereq-1.100640.tar.gz","name":"Dist-Zilla-Plugin-AutoPrereq","path":"J/JQ/JQUELIN/Dist-Zilla-Plugin-AutoPrereq-1.100640.tar.gz"}';
print "injecting: $json\n";

my $config = do 'config.pl';
my $c = FrePAN->bootstrap(config => $config);

$FrePAN::Worker::VERBOSE = 1;
FrePAN::Worker::ProcessDist->run(
    decode_json($json)
);

exit;
