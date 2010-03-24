package FrePAN::Web::C::Root;
use Amon::Web::C;
use Data::Page;

sub index {
    my $page = param('page') || 1;
       $page =~ /^[0-9]+$/ or die "bad page number: $page";
    my $rows_per_page = 20;

    my $dbh = db->dbh;
    my $entries = $dbh->selectall_arrayref(
        "SELECT SQL_CALC_FOUND_ROWS dist.name, dist.author, dist.version, dist.abstract, changes.body AS diff, meta_author.email AS email FROM dist LEFT JOIN changes ON (changes.dist_id=dist.dist_id) LEFT JOIN meta_author ON ( meta_author.pause_id=dist.author) ORDER BY released DESC LIMIT @{[ $rows_per_page + 1 ]} OFFSET @{[ $rows_per_page*($page-1) ]}",
        { Slice => {} }
    );
    my $total_entries = $dbh->selectrow_array(
        'SELECT FOUND_ROWS();'
    );

    my $pager = Data::Page->new();
    $pager->total_entries($total_entries);
    $pager->entries_per_page(20);
    $pager->current_page($page);

    my $cpan = model('CPAN');
    for (@$entries) {
        $_->{gravatar_url} = $cpan->email2gravatar_url($_->{email});
    }
    render("index.mt", $entries, $pager);
}

sub about {
    render('about.mt')
}

1;
