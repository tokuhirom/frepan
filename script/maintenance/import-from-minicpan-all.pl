# import whole dists from minicpan
use strict;
use warnings;
use FrePAN;
use Amon2::Declare;
use CPAN::DistnameInfo;
use Log::Minimal;
use Path::Class;
use FrePAN::M::Injector;
use Try::Tiny;

my $c = FrePAN->bootstrap();

my $minicpan = shift || FrePAN->minicpan_dir;

for my $char ('A'..'Z') {
    print "--- $char\n";
    my $char_dir = dir($minicpan, 'authors', 'id', $char);
    unless (-d $char_dir) {
        infof("missing char dir: %s", $char_dir);
        next;
    }

    $char_dir->recurse(
        callback => sub {
            my $f = shift;
            return unless -f $f;
            return if "$f" =~ /CHECKSUMS$/;
            print "- $f\n";
            infof("# $f");
            (my $path = "$f") =~ s!^\Q$minicpan\E/?authors/id/!!;
            my $info = CPAN::DistnameInfo->new($path);
            my $upload = $c->db->single(
                meta_uploads => {
                    pause_id     => $info->cpanid,
                    dist_name    => $info->dist,
                    dist_version => $info->version,
                }
            );
            unless ($upload) {
                critf("missing uploads for: $f");
                return;
            }

            try {
                FrePAN::M::Injector->inject(
                    name     => $info->dist,
                    path     => $path,
                    released => $upload->released,
                    force    => 1,
                    version  => $info->version,
                    author   => $info->cpanid,
                );
            } catch {
                critf("error $f: $_");
            };
        }
    );
}

