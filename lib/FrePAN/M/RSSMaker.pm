package FrePAN::M::RSSMaker;
# ABSTRACT: This module generates rss.
use strict;use warnings;
use XML::Feed;
use autodie;
use Amon2::Declare;
use FrePAN::M::CPAN;
use Text::Xslate::Util qw/html_escape/;
use Log::Minimal;

sub write_file {
    my ($fname, $content) = @_;
    open my $fh, '>', $fname;
    print {$fh} $content;
    close $fh;
}

sub generate {
    my $class = shift;

    my $c = c;

    my $feed = XML::Feed->new('RSS', version => 2.0);
    $feed->title('Yet Another CPAN Recent Changes');
    $feed->link('http://frepan.org/');
    my $iter = $c->db->search_by_sql(
        q{SELECT
            dist.dist_id, dist.name, dist.author, dist.version, dist.path, dist.abstract, changes.body AS diff, dist.released, meta_author.gravatar_id
            FROM dist
                LEFT JOIN meta_author ON (dist.author=meta_author.pause_id)
                LEFT JOIN changes ON (changes.dist_id = dist.dist_id)
            ORDER BY dist.released DESC
            LIMIT 10}
    );
    while (my $row = $iter->next) {
        $feed->add_entry(do {
            my $e = XML::Feed::Entry->new('RSS');
               $e->title(join(' ', $row->name, $row->version));
               $e->link("http://beta.metacpan.org/release/@{[ $row->name ]}/");
               $e->author($row->author);
               $e->issued(do {
                    DateTime->from_epoch(epoch => $row->released)
               });
               $e->summary($row->diff);
               $e->content(make_content($row));
               $e;
        });
    }
    my $path = c->config->{'M::RSSMaker'}->{path} // die;
    infof("save rss to $path");
    write_file($path, $feed->as_xml());
    return $feed->as_xml;
}

sub make_content {
    my ($row) = @_;

    my $html;
    if ($row->gravatar_id) {
        $html .= qq{<img src="http://gravatar.com/avatar/@{[ $row->gravatar_id ]}?s=80&d=http://st.pimg.net/tucs/img/who.png" width="80" height="80" /><br />};
    }

    $html .= <<"...";
<pre>@{[ html_escape($row->diff || '') ]}</pre>
<a href="http://search.cpan.org/dist/@{[ $row->name ]}/">search.cpan.org</a><br />
<a href="http://cpan.cpantesters.org/authors/id/@{[ html_escape($row->path) ]}">Download</a>
...

    return $html;
}

1;
