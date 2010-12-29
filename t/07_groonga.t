use strict;
use warnings;
use utf8;
use Test::More;
use FrePAN::FTS;
use Test::TCP;
use File::Temp;
use Log::Minimal;
use File::Which;
use Scope::Guard;

my $groonga = which('groonga');
plan skip_all => "missin groonga" unless $groonga;

my $tmp = tmpnam();
my $server = Test::TCP->new(
    code => sub {
        my $port = shift;
        exec $groonga, '-s', '-p' => $port, '--protocol' => 'http', '-n', $tmp;
    },
);
my $guard = Scope::Guard->new( sub { unlink $tmp });
my $fts = FrePAN::FTS->new(host => '127.0.0.1', port => $server->port);
eval { $fts->setup };
ok !$@, 'setup successfully.';
$fts->insert(
    file_id     => 1,
    package     => 'Encode::JP::Mobile',
    description => 'for mobile',
    text        => "こんにちは。せかい。"
);
$fts->insert(
    file_id     => 2,
    package     => 'Text::MicroTemplate',
    description => 'lightweight template engine',
    text        => "てけてけ。"
);
{
    my $result = $fts->search(query => 'てけてけ', rows => 100, page =>1);
    is_deeply([map { $_->{file_id} } @{$result->rows}], [2]);
}
{
    my $result = $fts->search(query => 'せかい', rows => 100, page =>1);
    is_deeply([map { $_->{file_id} } @{$result->rows}], [1]);
}
$fts->delete(1);
{
    my $result = $fts->search(query => 'せかい', rows => 100, page =>1);
    is scalar($result->pager->total_entries), 0;
}

done_testing;

