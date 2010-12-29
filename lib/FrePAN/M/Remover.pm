package FrePAN::M::Remover;
# ========================================================================= 
# remove the deleted files from CPAN.
#
# ========================================================================= 
use strict;
use warnings;
use utf8;
use YAML;
use LWP::UserAgent;
use Smart::Args;
use Try::Tiny;
use JSON::XS;
use Log::Minimal;
use FrePAN::M::CPAN;

my $url = 'http://cpan.cpantesters.org/authors/RECENT-1W.yaml';

sub run {
    args my $class, my $c;

    my @paths = $class->fetch_data();
    for my $path (@paths) {
        my $dist = FrePAN::M::CPAN->dist_from_path($path);
        if ($dist) {
            infof("removing $path");
            $class->remove_dist(
                c    => $c,
                dist => $dist,
            );
        } else {
            infof("$path is not found in RDBMS.");
        }
    }
}

sub fetch_data {
    my $ua = LWP::UserAgent->new(agent => "FrePAN/$FrePAN::VERSION");
    my $res = $ua->get($url);
    $res->is_success or die $res->status_line . " : " . $res->content;
    my $data = eval { YAML::Load($res->content) } or die "Cannot parse yaml: $@";
    return grep !/\.(?:meta|readme)$/, map { $_->{path} } grep { $_->{type} eq 'delete' } @{$data->{recent}};
}

sub remove_dist {
    args my $class, my $c, my $dist => {isa => 'FrePAN::DB::Row::Dist'};

    $dist->remove_from_fts();
    $dist->delete_files();
    $dist->delete();
}

1;

