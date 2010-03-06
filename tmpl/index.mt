? my ($dists, $page, $has_next) = @_;
? extends 'base.mt';
? block body_id => 'RootPage';
? block title => 'FrePAN page';
? block content => sub {

<a href="http://feeds.feedburner.com/YetAnotherCpanRecentChanges">RSS</a>

Yes, This is FrePAN. Freshness CPAN site.
This is only for freshness.

<div class="modules">
? for my $dist (@$dists) {
<div class="module">
    <h3><img src="/static/img/icons/module.png" /><a href="/~<?= lc $dist->author?>/<?= $dist->name ?>-<?= $dist->version ?>/"><?= $dist->name ?> <?= $dist->version ?></a></h3>
    <div class="abstract">
        <?= $dist->abstract ?>
    </div>
    <div class="author">
        <img src="<?= $dist->{gravatar_url} ?>" class="gravatar" width="80" height="80" />
        <a href="http://search.cpan.org/~<?= lc $dist->author ?>/"><?= lc $dist->author ?></a>
    </div>
</div>
? }
</div>

<div class="clear-both"></div>

? };
