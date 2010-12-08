use strict;
use warnings;
use utf8;

package FrePAN::Script::FriendFeed;
use Log::Minimal;
use Getopt::Long::Descriptive;
use AE;
use AnyEvent::FriendFeed::Realtime;
use Log::Minimal;
use FrePAN::M::Injector;
use FrePAN::M::FriendFeed;
use Time::HiRes qw/gettimeofday tv_interval/;
use Time::Piece;

sub new {
    my $class = shift;
    my ($opt, $usage) = describe_options(
        "$0 %o",
        ['help|h' => 'print usage and exit'],
        ['batch'  => 'debug run'],
    );
    print($usage->text), exit if $opt->help;
    bless {batch => $opt->batch}, $class;
}

sub run {
    my $self = shift;
    if ($self->{batch}) {
        $self->batch_run();
    } else {
        $self->realtime_run();
    }
}

sub batch_run {
    my $self = shift;

    require Furl;
    require JSON;

    my $furl = Furl->new();
    my $url = 'http://friendfeed-api.com/v2/feed/cpan?format=json';
    my $res = $furl->get($url);
    die "cannot fetch from friendfeed: " . $res->status_line unless $res->is_success;

    my $data = JSON::decode_json($res->content);
    for my $entry (@{$data->{entries}}) {
        $self->on_entry($entry);
    }
}

sub realtime_run {
    my $self = shift;

    my $cv = AE::cv();
    my $client = AnyEvent::FriendFeed::Realtime->new(
        request => "/feed/cpan",
        on_error => sub {
            my $err = shift;
            critf("error occured: %s", ddf($err));
            $cv->send();
        },
        on_entry => sub { $self->on_entry($_[0]) },
    );
    infof("ready to run");
    $cv->recv();
    infof("die on error...");
    &exit;
}

# {'created' => bless( do{\(my $o = 1)}, 'JSON::XS::Boolean' ),'body' => 'WWW-HtmlUnit 0.10 by Brock Wilcox - <a rel="nofollow" href="http://cpan.cpantesters.org/authors/id/A/AW/AWWAIID/WWW-HtmlUnit-0.10.tar.gz" title="http://cpan.cpantesters.org/authors/id/A/AW/AWWAIID/WWW-HtmlUnit-0.10.tar.gz">http://cpan.cpantesters.org/authors...</a>','to' => [{'name' => 'CPAN','id' => 'cpan','type' => 'group'}],'date' => '2010-11-23T03:26:39Z','from' => {'name' => 'CPAN bot','id' => 'cpanbot','type' => 'user'},'url' => 'http://friendfeed.com/cpan/be3430df/htmlunit-0-10-by-brock-wilcox','id' => 'e/be3430df168c4d9d9d473d67380c8fa4'}
sub on_entry {
    my ($self, $entry) = @_;

    infof("received entry: %s", ddf($entry));

    my $start_at = [gettimeofday];

    my $body = $entry->{body} // die;
    my $date = $entry->{date} // die;

    my $released = Time::Piece->strptime($date, '%Y-%m-%dT%H:%M:%SZ')->epoch;
    my ($name, $version, $path) = FrePAN::M::FriendFeed->parse_entry($body);
    my $author = FrePAN::M::FriendFeed->path2author($path);
    unless ($name) {
        critf("cannot parse body: %s", $body);
        return;
    }
    debugf("name: $name, version: $version, author: $author, path: $path, released: $released");
    FrePAN::M::Injector->inject(
        name     => $name,
        version  => $version,
        path     => $path,
        author   => $author,
        released => $released,
    );

    my $end_at = [gettimeofday];
    my $elapsed = tv_interval($start_at, $end_at);
    infof("finished $name. time elapsed $elapsed seconds");
}

1;

