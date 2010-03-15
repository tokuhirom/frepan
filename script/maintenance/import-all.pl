# import whole dists from minicpan
use FrePAN;
use FrePAN::Worker::ProcessDist;
use Amon::Sense;
use Amon::Declare;
use CPAN::DistnameInfo;

my $config = do 'config.pl';
my $c = FrePAN->bootstrap(config => $config);

$FrePAN::Worker::VERBOSE = 1;
$FrePAN::Worker::ProcessDist::DEBUG = 1;

my $minicpan = $c->model('CPAN')->minicpan;
dir($minicpan, 'authors', 'id')->recurse(
    callback => sub {
        my $f = shift;
        return unless -f $f;
        print "- $f\n";
        (my $path = "$f") =~ s!^\Q$minicpan\E/?authors/id/!!;
        my $info = CPAN::DistnameInfo->new($path);
        my $upload = db->single(
            meta_uploads => {
                pause_id     => $info->cpanid,
                dist_name    => $info->dist,
                dist_version => $info->version,
            }
        );
        unless ($upload) {
            logger->error("missing error");
            next;
        }
        my $data = {
            version => $info->version,
            url     => "http://cpan.yahoo.com/authors/id/$path",
            name    => $info->dist,
            path    => $path,
            released => $upload->released,
        };
        FrePAN::Worker::ProcessDist->run(
            $data
        );
    }
);

