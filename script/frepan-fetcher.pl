use strict;
use warnings;
use AnyEvent::Watchdog;
use AE;
use AnyEvent::FriendFeed::Realtime;
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use FrePAN;
use AnyEvent::Gearman::Client;
use Perl6::Say;

GetOptions(
    'config=s'     => \my $config,
);
$config or pod2usage();
$config = do $config or die "cannot load $config: $@";
my $c = FrePAN->bootstrap(config => $config);
my $username   = $c->config->{FriendFeed}->{username};
my $remote_key = $c->config->{FriendFeed}->{remote_key};

my $gearman = AnyEvent::Gearman::Client->new(
    job_servers => [ '127.0.0.1' ],
);

my $ff = AnyEvent::FriendFeed::Realtime->new(
    request => "/feed/cpan",
    on_entry => sub {
        my $entry = shift;
        my $info = parse_entry($entry->{body});
        return unless $info;

        $gearman->add_task(
            'frepan/add_dist' => $info,
            on_complete => sub {
                say "complete $info->{dist}";
            },
            on_fail => sub {
                say "fail $info->{dist}";
            },
        );
    },
);

AE::cv->recv();
die "Cannot";

sub parse_entry {
    my $body = shift;

    if ($body =~ m!^([\w\-]+) ([0-9\._]*) by (.+?) - <a.*href="(http:.*?/authors/id/(.*?\.tar\.gz))"!) {
        return {
            name        => $1,
            version     => $2,
            # author_full => $3,
            url         => $4,
            path        => $5,
        };
    }

    return;
}

__END__

=head1 SYNOPSIS

    % frepan-fetcher.pl --config=CONFIG

