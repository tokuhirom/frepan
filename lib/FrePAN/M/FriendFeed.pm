package FrePAN::M::FriendFeed;
use strict;
use warnings;
use utf8;
use 5.10.1;
use Carp ();

sub parse_entry {
    my ($class, $body) = @_;

    # version number:
    #   1.6.3a
    #   v1.0.3
    #   PNI-Node-Tk 0.02-withoutworldwriteables by Casati Gianluca <-- yes. it's invalid. but, parser should show tolerance.
    #   FusionInventory-Agent 2.1_rc1 by FusionInventory Project
    if ($body =~ m!(?<name>\S+) (?<version>\S+) by (?:.+?) - <a.*href="http:.*?/authors/id/(?<path>.*?\.tar\.gz)"!) {
         # name, version, path
        return ($+{name}, $+{version}, $+{path});
    }

    warn "cannot match!: $body";
    return;
}

sub path2author {
    my ($class, $path) = @_;

    Carp::croak "missing mandatory parameter 'path'" unless $path;
    my ($author) = ($path =~ m{^./../([^/]+)/});
    die "cannot detect author: $path" unless $author;
    return $author;
}

1;

