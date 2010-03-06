package FrePAN::Web::C::Root;
use Amon::Web::C;

sub index {
    my $page = param('page') || 1;
    my $rows_per_page = 20;

    my @entries = db->search(
        'dist' => { },
        {
            order_by => {'dist_id' => 'DESC'},
            limit    => $rows_per_page+1,
            offset   => $rows_per_page*($page-1),
        }
    );
    my $has_next =  ($rows_per_page+1 == @entries);
    if ($has_next) { pop @entries }

    for (@entries) {
        $_->{gravatar_url} = model('CPAN')->pause_id2gravatar_url($_->author);
    }
    render("index.mt", \@entries, $page, $has_next);
}

sub about {
    render('about.mt')
}

1;
