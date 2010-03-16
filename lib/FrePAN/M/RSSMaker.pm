package FrePAN::M::RSSMaker;
# ABSTRACT: This module generates rss.
use strict;use warnings;
use XML::Feed;
use autodie;

sub new {
    my ($class, $args) = @_;
    bless {%$args}, $class;
}

sub write_file {
    my ($fname, $content) = @_;
    open my $fh, '>', $fname;
    print {$fh} $content;
    close $fh;
}

sub generate {
    my $self = shift;

    my $c = Amon->context;

    my $feed = XML::Feed->new('RSS', version => 2.0);
    $feed->title('Yet Another CPAN Recent Changes');
    $feed->link('http://frepan.64p.org/');
    my $iter = $c->db->search_by_sql(
        q{SELECT dist.name, dist.author, dist.version, dist.path, dist.abstract, changes.body AS diff, dist.released FROM dist LEFT JOIN changes ON (changes.dist_id = dist.dist_id) ORDER BY dist.released DESC LIMIT 10}
    );
    while (my $row = $iter->next) {
        $feed->add_entry(do {
            my $gravatar = $c->model('CPAN')->pause_id2gravatar_url($row->author);
            my $e = XML::Feed::Entry->new('RSS');
               $e->title(join(' ', $row->name, $row->version));
               $e->link("http://frepan.64p.org/~@{[ lc($row->author) ]}/@{[ $row->name ]}-@{[ $row->version ]}/");
               $e->author($row->author);
               $e->issued(do {
                    DateTime->from_epoch(epoch => $row->released)
               });
               $e->summary($row->diff);
               $e->content(make_content($row, $gravatar));
               $e;
        });
    }
    write_file($self->{path}, $feed->as_xml());
    return $feed->as_xml;
}

sub make_content {
    my ($row, $gravatar) = @_;

    return <<"...";
<img src="$gravatar" /><br />
<pre>@{[ $row->diff || '' ]}</pre>
<a href="http://search.cpan.org/dist/@{[ $row->name ]}/">search.cpan.org</a><br />
<a href="http://cpan.cpantesters.org/authors/id/@{[ $row->path ]}">Download</a>
...
}

1;
