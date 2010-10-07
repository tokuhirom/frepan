#!/usr/local/app/perl-5.12.1/bin/perl

eval 'exec /usr/local/app/perl-5.12.1/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell
use strict;
use warnings;
use File::Path qw/mkpath/;
use Getopt::Long;
use Pod::Usage;
use Text::MicroTemplate ':all';

our $module;
our $dispatcher = 'RouterSimple';
GetOptions(
    'dispatcher=s' => \$dispatcher,
    'skinny'       => \our $skinny,
    'help'         => \my $help,
) or pod2usage(0);
pod2usage(1) if $help;

my $confsrc = <<'...';
-- lib/$path.pm
package <%= $module %>;
use strict;
use warnings;
use parent qw/Amon2/;
our $VERSION='0.01';

use Amon2::Config::Simple;
sub load_config { Amon2::Config::Simple->load(shift) }

__PACKAGE__->load_plugin('LogDispatch');

<% if ($skinny) { %>
sub db {
    my ($self) = @_;
    $self->{db} //= do {
        my $conf = $self->config->{'DBIx::Skinny'} or die "missing configuration for 'DBIx::Skinny'";
        <%= $module %>::DB->new($conf);
    };
}
<% } %>

1;
-- lib/$path/Web.pm
package <%= $module %>::Web;
use strict;
use warnings;
use parent qw/<%= $module %> Amon2::Web/;

# load all controller classes
use Module::Find ();
Module::Find::useall("<%= $module %>::Web::C");

# custom classes
use <%= $module %>::Web::Request;
use <%= $module %>::Web::Response;
sub create_request  { <%= $module %>::Web::Request->new($_[1]) }
sub create_response { shift; <%= $module %>::Web::Response->new(@_) }

# dispatcher
use <%= $module %>::Web::Dispatcher;
sub dispatch {
    return <%= $module %>::Web::Dispatcher->dispatch($_[0]) or die "response is not generated";
}

# optional configuration
__PACKAGE__->add_config(
    'Text::Xslate' => {
        'syntax'   => 'TTerse',
        'module'   => [ 'Text::Xslate::Bridge::TT2Like' ],
        'function' => {
            c => sub { Amon2->context() },
            uri_with => sub { Amon2->context()->req->uri_with(@_) },
            uri_for  => sub { Amon2->context()->uri_for(@_) },
        },
    }
);

# setup view class
use Tiffany::Text::Xslate;
{
    my $view_conf = __PACKAGE__->config->{'Text::Xslate'};
    my $view = Tiffany::Text::Xslate->new($view_conf);
    sub create_view { $view }
}

# load plugins
# __PACKAGE__->load_plugins('Web::FillInFormLite');
# __PACKAGE__->load_plugins('Web::NoCache');

1;
-- lib/$path/Web/Dispatcher.pm
package <%= $module %>::Web::Dispatcher;
<% if ($dispatcher eq 'RouterSimple') { %>
use Amon2::Web::Dispatcher::RouterSimple;

connect '/' => 'Root#index';
<% } else { %>
use Amon2::Web::Dispatcher::Lite;

any '/' => sub {
    my ($c) = @_;
    $c->render('index.tt');
};
<% } %>

1;
-- lib/$path/Web/Request.pm
package <%= $module %>::Web::Request;
use strict;
use parent qw/Amon2::Web::Request/;
1;
-- lib/$path/Web/Response.pm
package <%= $module %>::Web::Response;
use strict;
use parent qw/Amon2::Web::Response/;
1;
-- lib/$path/DB.pm skinny
package <%= $module %>::DB;
use DBIx::Skinny;
1;
-- lib/$path/Web/C/Root.pm RouterSimple
package <%= $module %>::Web::C::Root;
use strict;
use warnings;

sub index {
    my ($class, $c) = @_;
    $c->render("index.tt");
}

1;
-- config/development.pl
+{
<% if ($skinny) { %>
    'DBIx::Skinny' => {
        dsn => 'dbi:SQLite:dbname=test.db',
        username => '',
        password => '',
    },
<% } %>
    'Text::Xslate' => {
        path => ['tmpl/'],
    },
    'Log::Dispatch' => {
        outputs => [
            ['Screen',
            min_level => 'debug',
            stderr => 1,
            newline => 1],
        ],
    },
};
-- lib/$path/ConfigLoader.pm
package <%= $module %>::ConfigLoader;
use strict;
use warnings;
use parent 'Amon2::ConfigLoader';
1;
-- script/make_schema.pl
use strict;
use warnings;
use <%= $module %>;
use DBIx::Skinny::Schema::Loader qw/make_schema_at/;
use FindBin;

my $c = <%= $module %>->bootstrap;
my $conf = $c->config->{'DBIx::Skinny'};

my $schema = make_schema_at( '<%= $module %>::DB::Schema', {}, $conf );
my $dest = File::Spec->catfile($FindBin::Bin, '..', 'lib', '<%= $module %>', 'DB', 'Schema.pm');
open my $fh, '>', $dest or die "cannot open file '$dest': $!";
print {$fh} $schema;
close $fh;
-- sql/my.sql
CREATE TABLE foo (
    foo_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY
) ENGINE=InnoDB charset=utf-8;
-- tmpl/index.tt
[% INCLUDE 'include/header.tt' %]

hello, Amon2 world!

[% INCLUDE 'include/footer.tt' %]
-- tmpl/include/header.tt
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <title><%= $dist %></title>
    <meta http-equiv="Content-Style-Type" content="text/css" />  
    <meta http-equiv="Content-Script-Type" content="text/javascript" />  
    <link href="[% uri_for('/static/css/main.css') %]" rel="stylesheet" type="text/css" media="screen" />
</head>
<body>
    <div id="Container">
        <div id="Header">
            <a href="[% uri_for('/') %]">Amon2 Startup Page</a>
        </div>
        <div id="Content">
-- tmpl/include/footer.tt
        </div>
        <div id="FooterContainer"><div id="Footer">
            Powered by Amon2
        </div></div>
    </div>
</body>
</html>
-- htdocs/static/css/main.css
/* reset.css */
html, body, div, span, object, iframe, h1, h2, h3, h4, h5, h6, p, blockquote, pre, a, abbr, acronym, address, code, del, dfn, em, img, q, dl, dt, dd, ol, ul, li, fieldset, form, label, legend, table, caption, tbody, tfoot, thead, tr, th, td {margin:0;padding:0;border:0;font-weight:inherit;font-style:inherit;font-size:100%;font-family:inherit;vertical-align:baseline;}
body {line-height:1.5;}
table {border-collapse:separate;border-spacing:0;}
caption, th, td {text-align:left;font-weight:normal;}
table, td, th {vertical-align:middle;}
blockquote:before, blockquote:after, q:before, q:after {content:"";}
blockquote, q {quotes:"" "";}
a img {border:none;}

/* main */
html,body {height:100%;}
body > #Container {height:auto;}

body {
    background-image: url(http://lab.rails2u.com/bgmaker/slash.png?margin=3&linecolor=FF0084&bgcolor=000000);
    color: white;
    font-family: "メイリオ","Hiragino Kaku Gothic Pro","ヒラギノ角ゴ Pro W3","ＭＳ Ｐゴシック","Osaka",sans-selif;
}

#Container {
    width: 780px;
    margin-left: auto;
    margin-right: auto;
    margin-bottom: 0px;
    border-left: black solid 1px;
    border-right: black solid 1px;
    margin-top: 0px;
    height: 100%;
    min-height:100%;
    background-color: white;
    color: black;
}

#Header {
    background-image: url(http://lab.rails2u.com/bgmaker/gradation.png?margin=3&linecolor=FF0084&bgcolor=000000);
    height: 50px;
    font-size: 36px;
    padding: 2px;
    text-align: center;
}

#Header a {
    color: black;
    font-weight: bold;
    text-decoration: none;
}

#Content {
    padding: 10px;
}

#FooterContainer {
    border-top: 1px solid black;
    font-size: 10px;
    color: black;
    position:absolute;
    bottom:0px;
    height:20px;
    width:780px;
}
#Footer {
    text-align: right;
    padding-right: 10px;
    padding-top: 2px;
}

-- $dist.psgi
use File::Spec;
use File::Basename;
use local::lib File::Spec->catdir(dirname(__FILE__), 'extlib');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use <%= $module %>::Web;
use Plack::Builder;

builder {
    enable 'Plack::Middleware::Static',
        path => qr{^/static/},
        root => './htdocs/';
    enable 'Plack::Middleware::ReverseProxy';
    <%= $module %>::Web->to_app();
};
-- Makefile.PL
use inc::Module::Install;
all_from "lib/<%= $path %>.pm";

tests 't/*.t t/*/*.t t/*/*/*.t';
requires 'Amon2';
requires 'Text::Xslate';
requires 'Text::Xslate::Bridge::TT2Like';
requires 'Plack::Middleware::ReverseProxy';
requires 'HTML::FillInForm::Lite';
requires 'Time::Piece';
<% if ($skinny) { %>
requires 'DBIx::Skinny';
requires 'DBIx::Skinny::Schema::Loader';
<% } %>
recursive_author_tests('xt');

WriteAll;
-- t/01_root.t
use strict;
use warnings;
use Plack::Test;
use Plack::Util;
use Test::More;

my $app = Plack::Util::load_psgi '<%= $dist %>.psgi';
test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => 'http://localhost/');
        my $res = $cb->($req);
        is $res->code, 200;
        diag $res->content if $res->code != 200;
    };

done_testing;
-- t/02_mech.t
use strict;
use warnings;
use Plack::Test;
use Plack::Util;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI';

my $app = Plack::Util::load_psgi '<%= $dist %>.psgi';

my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
$mech->get_ok('/');

done_testing;
-- xt/01_podspell.t
use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
<%= $module %>
Tokuhiro Matsuno
Test::TCP
tokuhirom
AAJKLFJEF
GMAIL
COM
Tatsuhiko
Miyagawa
Kazuhiro
Osawa
lestrrat
typester
cho45
charsbar
coji
clouder
gunyarakun
hio_d
hirose31
ikebe
kan
kazeburo
daisuke
maki
TODO
kazuhooku
FAQ
Amon2
DBI
PSGI
URL
XS
env
.pm
-- xt/02_perlcritic.t
use strict;
use Test::More;
eval q{ use Test::Perl::Critic -profile => 'xt/perlcriticrc' };
plan skip_all => "Test::Perl::Critic is not installed." if $@;
all_critic_ok('lib');
-- xt/03_pod.t
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
-- xt/perlcriticrc
[TestingAndDebugging::ProhibitNoStrict]
allow=refs
[-Subroutines::ProhibitSubroutinePrototypes]
[TestingAndDebugging::RequireUseStrict]
equivalent_modules = Mouse Mouse::Role Moose Amon2 Amon2::Web Amon2::Web::C Amon2::V::MT::Context Amon2::Web::Dispatcher Amon2::V::MT Amon2::Config DBIx::Skinny DBIx::Skinny::Schema Amon2::Web::Dispatcher::HTTPxDispatcher Any::Moose Amon2::Web::Dispatcher::RouterSimple DBIx::Skinny DBIx::Skinny::Schema Amon2::Web::Dispatcher::Lite common::sense
[-Subroutines::ProhibitExplicitReturnUndef]
-- .gitignore
Makefile
inc/
MANIFEST
*.bak
*.old
nytprof.out
...

&main;exit;

sub _mkpath {
    my $d = shift;
    print "mkdir $d\n";
    mkpath $d;
}

sub main {
    $module = shift @ARGV or pod2usage(0);
    $module =~ s!-!::!g;

    # $module = "Foo::Bar"
    # $dist   = "Foo-Bar"
    # $path   = "Foo/Bar"
    my @pkg  = split /::/, $module;
    my $dist = join "-", @pkg;
    my $path = join "/", @pkg;

    mkdir $dist or die $!;
    chdir $dist or die $!;
    _mkpath "lib/$path";
    _mkpath "lib/$path/Web/";
    _mkpath "lib/$path/Web/C" unless $dispatcher eq 'Lite';
    _mkpath "lib/$path/M";
    _mkpath "lib/$path/DB/";
    _mkpath "tmpl";
    _mkpath "tmpl/include/";
    _mkpath "t";
    _mkpath "xt";
    _mkpath "sql/";
    _mkpath "config/";
    _mkpath "script/";
    _mkpath "script/cron/";
    _mkpath "script/tmp/";
    _mkpath "script/maintenance/";
    _mkpath "htdocs/static/css/";
    _mkpath "htdocs/static/img/";
    _mkpath "htdocs/static/js/";
    _mkpath "extlib/";

    my $conf = _parse_conf($confsrc);
    while (my ($file, $tmpl) = each %$conf) {
        $file =~ s/(\$\w+)/$1/gee;
        my $code = Text::MicroTemplate->new(
            tag_start => '<%',
            tag_end   => '%>',
            line_start => '%',
            template => $tmpl,
        )->code;
        my $sub = eval "package main;our \$module; sub { Text::MicroTemplate::encoded_string(($code)->(\@_))}";
        die $@ if $@;

        my $res = $sub->()->as_string;

        print "writing $file\n";
        open my $fh, '>', $file or die "Can't open file($file):$!";
        print $fh $res;
        close $fh;
    }
}

sub _parse_conf {
    my $fname;
    my $res;
    my $tag;
    LOOP: for my $line (split /\n/, $confsrc) {
        if ($line =~ /^--\s+(\S+)(?:\s*(\S+))?$/) {
            $fname = $1;
            $tag   = $2;
        } else {
            $fname or die "missing filename for first content";
            next LOOP if $tag && $tag eq 'skinny' && !$skinny;
            next LOOP if $tag && $tag eq 'RouterSimple' && $dispatcher ne 'RouterSimple';
            $res->{$fname} .= "$line\n";
        }
    }
    return $res;
}

__END__

=head1 SYNOPSIS

    % amon-setup.pl MyApp

=head1 AUTHOR

Tokuhiro Matsuno

=cut

