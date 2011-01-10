use strict;
use warnings;
use utf8;

package FrePAN::FTS;
# ========================================================================= 
# Full Text Search(based on groonga)
# ========================================================================= 
use Class::Accessor::Lite 0.05 (
    new => 1,
    ro => [qw/host port/],
);
use Furl;
use URI::Escape;
use JSON qw/encode_json decode_json/;
use URI;
use Log::Minimal;
use Smart::Args;
use Data::Page;

sub schema {
    split /\n/, <<'...';
table_create --name File --flags TABLE_HASH_KEY --key_type ShortText
column_create --table File --name package --flags COLUMN_SCALAR --type Text
column_create --table File --name description --flags COLUMN_SCALAR --type Text
column_create --table File --name text --flags COLUMN_SCALAR --type Text
table_create --name Terms --flags TABLE_PAT_KEY|KEY_NORMALIZE --key_type ShortText --default_tokenizer TokenBigram
column_create --table Terms --name package --flags COLUMN_INDEX|WITH_POSITION --type File --source package
column_create --table Terms --name description --flags COLUMN_INDEX|WITH_POSITION --type File --source description
column_create --table Terms --name text --flags COLUMN_INDEX|WITH_POSITION --type File --source text
...
}

sub furl { shift->{furl} ||= Furl->new() }

sub setup {
    my $self = shift;
    for my $line ($self->schema) {
        my $url = $self->_make_url($line);
        my $res = $self->furl->get($url);
        $res->is_success or die "Cannot complete($url): " . $res->content;
    }
}

sub insert {
    args my $self,
         my $file_id,
         my $package,
         my $description,
         my $text,
         ;

    $file_id =~ /^\d+$/ or die "file_id must be int";
    my $uri = URI->new("http://$self->{host}:$self->{port}/d/load");
    $uri->query_form(
        table      => 'File',
        columns    => '_key,package,description,text',
        input_type => 'json',
        values     => encode_json(
            {
                _key        => $file_id,
                package     => $package,
                description => $description,
                text        => $text
            }
        )
    );
    my $res = $self->furl->get($uri->as_string);
    $res->is_success or die "Cannot insert: " . $res->content;
}

sub delete {
    my ($self, $file_id) = @_;
    my $uri = URI->new("http://$self->{host}:$self->{port}/d/delete");
    $uri->query_form(table => 'File', key => $file_id);
    my $res = $self->furl->get($uri->as_string);
    $res->is_success or die "Cannot delete: " . $res->code .':' . $res->content;
}

sub make_query {
    args_pos my $self, my $query;

    my $ret = '';
    for my $part (split /\s+/, $query) {
        if ($part =~ s/^-//) {
            $ret .= qq{ - "$part"} if $ret;
        } else {
            $ret .= qq{ + } if $ret;
            $ret .= qq{"$part"};
        }
    }
    debugf("QUERY IS: $ret");
    return $ret;
}

sub search {
    args my $self,
         my $query,
         my $rows,
         my $page,
         ;

    my $limit = $rows;
    my $offset = $rows * ( $page - 1 );

    # select --table Users --match_columns text --query 東京 --output_columns file_id
    # retval: [[return code, star at, elapsed time], [search result, drilledown result]]
    my $uri = URI->new("http://$self->{host}:$self->{port}/d/select");
    $uri->query_form(
        table          => 'File',
        match_columns  => 'package * 100 || description * 5 || text * 1',
        query          => $self->make_query($query),
        output_columns => '_key,_score',
        sortby         => '-_score',
        limit          => $limit,
        offset         => $offset,
        query_cache    => 'no',
    );
    debugf("Sending search query: %s", $uri);
    my $res = $self->furl->get($uri->as_string);
    $res->is_success or die "Cannot search: " . $res->content;
    debugf("search result: %s, %s", $uri, $res->content);
    my $data = decode_json($res->content);
    my $file_ids = $data->[1]->[0]; # return value is array of file_ids
    my $total_entries = (shift @$file_ids)->[0]; # matched count
    debugf("Keys: %s", ddf(shift @$file_ids)); # keys
    my @rows = map { +{file_id => $_->[0], score => $_->[1]}  } @$file_ids;

    my $pager = Data::Page->new();
    $pager->total_entries($total_entries);
    $pager->entries_per_page($rows);
    $pager->current_page($page);

    return FrePAN::FTS::SearchResult->new(
        pager    => $pager,
        rows     => \@rows,
    );
}

sub _make_url {
    my ($self, $line) = @_;

    my ($cmd, @args) = split /\s+/, $line;
    my $uri = URI->new("http://$self->{host}:$self->{port}/d/$cmd");
    my %query;
    while (my ($k, $v) = splice @args, 0, 2) {
        $k =~ s/^--//;
        $query{$k} = $v;
    }
    $uri->query_form(%query);
    return $uri->as_string;
}

package FrePAN::FTS::SearchResult;
use Class::Accessor::Lite (
    new => 1,
    ro  => [qw/pager rows/],
);

1;

