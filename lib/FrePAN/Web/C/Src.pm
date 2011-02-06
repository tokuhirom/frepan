use strict;
use warnings;
use utf8;

package FrePAN::Web::C::Src;
use FrePAN;

my $app =
  FrePAN::App::Directory->new( root => FrePAN->config->{srcdir} )->to_app;

sub show {
    my ( $class, $c ) = @_;

    my $env = +{ %{ $c->req->env } };
    $env->{PATH_INFO}   = '/' . $c->args->{splat}->[0];
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
    my ( $self, $file ) = @_;
    return -d $file || -f $file;
}

sub serve_plain_file {
    my ( $self, $env, $file ) = @_;

    open my $fh, "<:raw", $file
      or return $self->return_403;

    my @stat = stat $file;

    Plack::Util::set_io_path( $fh, Cwd::realpath($file) );

    return [
        200,
        [
            'Content-Type'   => 'text/plain;charset=utf-8',
            'Content-Length' => $stat[7],
            'Last-Modified'  => HTTP::Date::time2str( $stat[9] )
        ],
        $fh,
    ];
}

use Text::Xslate::Util qw/mark_raw html_escape/;

sub serve_plain_file_pretty {
    my ( $self, $c, $env, $file ) = @_;

    open my $fh, "<:raw", $file
      or return $self->return_403;
    my $src = do { local $/; <$fh> };
    my $path = File::Spec->abs2rel( $file, $self->root );

    return $c->render2(
        'title' => "$path - FrePAN",
        '#Content' => [
            'src/file.tx' => {
                path => $self->_make_bread_list($path),
                src  => $src,
            }
        ]
    )->finalize;
}

sub _make_bread_list {
    my ( $self, $path ) = @_;

    my @path = split( m{/}, $path );
    my @used_path;
    my @path_parts;
    while ( my $part = shift @path ) {
        if (@path) {
            push @path_parts,
              sprintf(
                q{<a href="/src/%s">%s</a>},
                html_escape( join( "/", @used_path, $part ) ),
                html_escape($part)
              );
        }
        else {    # last part
            push @path_parts, html_escape($part);
        }
        push @used_path, $part;
    }
    return mark_raw( join( "&gt; ", @path_parts ) );
}

sub serve_path {
    my ( $self, $env, $dir ) = @_;
    my $c = c();

    if ( -f $dir ) {
        if ( $c->req->param('pretty') ) {
            return $self->serve_plain_file_pretty( $c, $env, $dir );
        }
        else {
            return $self->serve_plain_file( $env, $dir );
        }
    }

    my @files;

    opendir my $dh, $dir or die "Cannot open directory($dir): $!";
    my @children;
    while ( defined( my $ent = readdir($dh) ) ) {
        push @children, $ent;
    }

    for my $basename ( sort { $a cmp $b } @children ) {
        next if $basename eq '.';
        my $file = "$dir/$basename";
        my $url  = $env->{SCRIPT_NAME} . $env->{PATH_INFO};
        $url .= '/' unless $url =~ m{/$};
        $url .= $basename;

        my $is_dir = -d $file;
        my @stat   = stat _;

        if ($is_dir) {
            $basename .= "/";
            $url      .= "/";
        }

        $url = join '/', map { uri_escape($_) } split m{/}, $url;

        push @files, +{ path => $url, basename => $basename, size => $stat[7] };
    }

    my $path = c()->req->path_info();
    $path =~ s!^/src/!!;

    return c()->render2(
        'title' => "$path - FrePAN",
        '#Content' => [
            'src/directory.tx' => {
                path  => $self->_make_bread_list($path),
                files => \@files,
            }
        ]
    )->finalize();
}

1;

