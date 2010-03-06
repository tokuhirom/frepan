? my ($dists, $page, $has_next) = @_;
? extends 'base.mt';
? block body_id => 'RootPage';
? block title => 'FrePAN';
? block content => sub {

FrePAN is realtime mirror site of cpan.<a href="/about">see here for more details</a>.

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

<a href="http://feeds.feedburner.com/YetAnotherCpanRecentChanges">
<img src="/static/img/icons/feed.png" width="28" height="28" />
</a>
<br />

<div class="clear-both"></div>

? };
