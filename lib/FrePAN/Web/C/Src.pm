use strict;
use warnings;
use utf8;

package FrePAN::Web::C::Src;
use FrePAN;

my $app = FrePAN::App::Directory->new(root => FrePAN->config->{srcdir})->to_app;

sub show {
    my ($class, $c) = @_;

    my $env = +{%{$c->req->env}};
    $env->{PATH_INFO} = '/' . $c->args->{splat}->[0];
    $env->{SCRIPT_NAME} = "/src";
    my $res = $app->($env);
    return $c->create_response(@$res);
}

package FrePAN::App::Directory;
use parent qw/Plack::App::File/;
use Amon2::Declare;

# /usr/local/app/perl-5.12.2/lib/site_perl/5.12.2/Plack/App/Directory.pm
use DirHandle;
use URI::Escape;

sub should_handle {
    my($self, $file) = @_;
    return -d $file || -f $file;
}

sub serve_path {
    my($self, $env, $dir, $fullpath) = @_;

    if (-f $dir) {
        return $self->SUPER::serve_path($env, $dir, $fullpath);
    }

    my @files;

    opendir my $dh, $dir or die "Cannot open directory($dir): $!";
    my @children;
    while (defined(my $ent = readdir($dh))) {
        push @children, $ent;
    }

    for my $basename (sort { $a cmp $b } @children) {
        next if $basename eq '.';
        my $file = "$dir/$basename";
        my $url = $env->{SCRIPT_NAME} . $env->{PATH_INFO};
        $url .= '/' unless $url =~ m{/$};
        $url .= $basename;

        my $is_dir = -d $file;
        my @stat = stat _;

        if ($is_dir) {
            $basename .= "/";
            $url      .= "/";
        }

        $url = join '/', map {uri_escape($_)} split m{/}, $url;

        push @files, +{ path => $url, basename => $basename, size => $stat[7] };
    }

    return c()->render(
        'src/directory.tx' => {
            path  => c()->req->path_info(),
            files => \@files,
        }
    )->finalize();
}

1;

