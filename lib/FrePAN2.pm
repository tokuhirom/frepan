package FrePAN2;
use Mouse;
use strict;
use warnings FATAL => 'all';
use 5.010001;
our $VERSION = '0.02';

use JSON;
use LWP::UserAgent::Determined;
use HTTP::Request;
use Data::Dumper;
use Text::Xslate;
use version;
use File::Spec;
use File::HomeDir;
use Algorithm::Diff qw/diff/;
use XML::Feed;
use Cache::FileCache;
use FindBin;
use File::Basename;
use Cwd;

has 'cache' => (
    is      => 'rw',
    default => sub {
        Cache::FileCache->new(
            {
                'namespace'  => 'frepan-cache',
                'cache_root' => File::Spec->catfile(
                    File::HomeDir->my_home, '.frepan2-cache'
                ),
                'default_expires_in' => 600
            }
        );
    },
);

has ua => (
    is => 'rw',
    default => sub {
        my $self = shift;
        LWP::UserAgent::Determined->new(
            agent => "FrePAN2/$VERSION",
            timeout => 60
        );
    },
);

{
    my $BASE_DIR =
      File::Spec->catfile( Cwd::abs_path( dirname(__FILE__) ), '../' );
    sub base_dir { $BASE_DIR }
}

has xslate => (
    is => 'ro',
    default => sub {
        my $self = shift;
        Text::Xslate->new(
            syntax => 'TTerse',
            path   => [File::Spec->catfile($self->base_dir, 'tmpl')],
            module => ['Text::Xslate::Bridge::TT2Like'],
        );
    },
);

sub write_file {
    my ($fname, $content) = @_;
    open my $fh, '>', $fname or die "Cannot open file $fname: $!";
    print {$fh} $content;
}

sub run {
    my $self = shift;

    my $rss;
    if ($ENV{HTML_DEBUG}) {
        open my $fh, '<', File::Spec->catfile($self->base_dir, 'dat/index.rss') or die $!;
        $rss = XML::Feed->parse($fh);
    } else {
        $rss = $self->create_rss();
        write_file(File::Spec->catfile($self->base_dir, 'dat/index.rss') => $rss->as_xml);
    }

    my $html = $self->create_html($rss);
    write_file(File::Spec->catfile($self->base_dir, 'dat/index.html') => $html);
}

sub create_html {
    my ($self, $rss) = @_;
    $self->xslate->render('html.tt', {entries => [$rss->entries]});
}

sub create_rss {
    my ($self) = @_;
    
    my $feed = XML::Feed->new('RSS', version => 2.0);
    $feed->title('Yet Another CPAN Recent Changes');
    $feed->link('http://frepan.64p.org/');

    my @release = $self->search(
        '/release/_search',
        {
            size => $ENV{DEBUG} ? 1 : 20,
            from => 0,
            sort => [ { 'date' => { order => "desc" } } ],
            query => { match_all => {} },
            fields => [qw(name date author version status abstract distribution download_url date)],
        },
        1
    );

    for my $entry (@release) {
        my $link = "http://metacpan.org/release/$entry->{author}/$entry->{name}";
        my $author = eval { $self->call_api("/author/$entry->{author}") } || +{ };
        my $prev_version = $self->get_prev_version($entry->{distribution}, $entry->{version});
        my $changes_diff = $self->get_changes_diff($prev_version, $entry);
        my $diff_url = $prev_version ? "https://metacpan.org/diff/release/" . join('/', $prev_version->{author}, $prev_version->{name}, $entry->{author}, $entry->{name}) : undef;

        my $e = XML::Feed::Entry->new();
        $e->title($entry->{name} . ' ' . $entry->{author});
        $e->link($link);
        $e->author($entry->{author});
        $e->summary($changes_diff);
        $e->content(do {
            my $params = +{
                gravatar_url => $author->{gravatar_url},
                changes_diff => $changes_diff,
                link => $link,
                diff_url => $diff_url,
                map { $_ => $entry->{$_} } qw(download_url date name version distribution abstract author date),
            };
            $self->xslate->render('rss.tt', $params);
        });
        $feed->add_entry($e);
    }
    return $feed;
}


sub get_changes_diff {
    my ($self, $prev_version, $entry) = @_;
    $entry // die;

    return undef unless defined $prev_version;

    my $changes_new = $self->get_changes_file($entry->{name}, $entry->{author});
    my $changes_old = $self->get_changes_file($prev_version->{name}, $prev_version->{author});
    return '' unless defined $changes_old;
    return '' unless defined $changes_new;

    my $diff = diff [split /\n/, $changes_old], [split /\n/, $changes_new];
    my $ret = join("\n", map { $_->[2] } grep { $_->[0] eq '+' } @{$diff->[0]});
    return $ret;
}

sub get_changes_file {
    my ($self, $release, $author) = @_;

    my ($changes_fname) = map { $_->{name} } $self->search(
        '/file/_search' => {
            query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        and => [
                            { term => { release   => $release } },
                            { term => { author   => $author } },
                            { term => { level     => 0 } },
                            { term => { directory => \0 } },
                            {
                                or => [
                                    map { { term => { 'file.name' => $_ } } }
                                      qw(CHANGES Changes ChangeLog Changelog)
                                ]
                            }
                        ]
                    }
                }
            },
            fields => [qw(name)],
            size   => 10,
        }
    );
    unless ($changes_fname) {
        return;
    }

    # http://api.metacpan.org/source/DOY/Moose-2.0010/Changes
    my $src = $self->get_source($author, $release, '/' . $changes_fname);
    return $src;
}

sub get_prev_version {
    my ($class, $dist, $target_version) = @_;

    $target_version = eval { version->parse($target_version) };
    if ($@) {
        return undef;
    }
    for my $entry ($class->search_versions($dist)) {
        if (version->parse($entry->{version}) < $target_version) {
            return $entry;
        }
    }
    return undef;
}

sub search_versions {
    my ($class, $dist) = @_;
    $dist // die;

    return $class->search(
        '/release/_search',
        {
            'sort' => [ { 'date' => 'desc' } ],
            'fields' => [ 'name', 'date', 'author', 'version', 'status' ],
            'query'  => {
                'filtered' => {
                    'filter' => {
                        'and' => [
                            { 'term' => { 'release.distribution' => $dist } }
                        ]
                    },
                    'query' => { 'match_all' => {} }
                }
            },
            'size' => 100
        }
    );
}

sub create_request {
    my ($self, $path, $search) = @_;
    $path =~ s!^/!!; # normalize

    my $endpoint = 'http://api.metacpan.org/';
    my $url = $endpoint . $path;

    my $request = HTTP::Request->new('POST', $url);
    if ($search) {
        $request->content(encode_json($search));
        $request->content_type('application/json');
    }
    $request->content_length(length $request->content);
    warn $request->as_string;
    return $request;
}

# http://api.metacpan.org/source/DOY/Moose-2.0010/Changes
sub get_source {
    my ($self, $author, $release, $path) = @_;
    $path // die;

    my $uri = "http://api.metacpan.org/source/" . join('/', $author, $release, $path);
    if (my $cache_obj = $self->cache->get($uri)) {
        return $cache_obj;
    }
    my $res = $self->ua->get($uri);
    $res->is_success or die "Cannot fetch from API server: $>uri, " . $res->status_line;
    $self->cache->set($uri => $res->content);
    return $res->content;
}

sub call_api {
    my ($self, $path, $search, $no_cache) = @_;

    my $request = $self->create_request($path, $search);
    my $key = $request->uri . "xxx" . $request->content;
    if ((!$no_cache) && (my $cache_obj = $self->cache->get($key))) {
        return $cache_obj;
    }
    say "Fetching: $path" if $ENV{DEBUG};

    my $res = $self->ua->request($request);
    $res->is_success or die "Cannot fetch from API server: @{[ $request->uri ]}, " . $res->status_line;
    my $dat = eval { decode_json( $res->content ) } or die "Cannot parse JSON(@{[ $res->as_string ]}): " . $res->content;
    $self->cache->set($key => $dat);
    return $dat;
}

sub search {
    my ($self, $path, $search, $no_cache) = @_;

    my $dat = $self->call_api($path, $search, $no_cache);
    return map { $_->{fields} } @{ $dat->{hits}->{hits} };
}

no Mouse; __PACKAGE__->meta->make_immutable;
__END__

=encoding utf8

=head1 NAME

FrePAN2 -

=head1 SYNOPSIS

  use FrePAN2;

=head1 DESCRIPTION

FrePAN2 is

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
