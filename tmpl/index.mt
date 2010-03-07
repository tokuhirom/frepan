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
    <div class="module-info">
        <div class="abstract"><?= $dist->abstract ?></div>
        <pre class="changes"><?= $dist->diff ?></pre>
    </div>
    <div class="author">
        <a href="http://search.cpan.org/~<?= lc $dist->author ?>/">
        <img src="<?= $dist->{gravatar_url} ?>" class="gravatar" width="80" height="80" />
        <?= lc $dist->author ?>
        </a>
    </div>
    <div class="clear-both">&nbsp;</div>
</div>
? }
</div>

<div class="pager">
    <? if ($page != 1) { ?>
        <a href="<?= uri_for("/", {page => $page - 1 }) ?>" rel="prev" accesskey="4">&lt;Prev</a>
    <? } else { ?>
    &lt;Prev
    <? } ?>
    |
    <? if ($has_next) { ?>
    <a href="<?= uri_for("/", {page => $page + 1}) ?>" rel="next" accesskey="6">Next&gt;</a>
    <? } else { ?>
    Next&gt;
    <? } ?>
</div>

<div class="clear-both"></div>

<a href="http://feeds.feedburner.com/YetAnotherCpanRecentChanges">
<img src="/static/img/icons/feed.png" width="28" height="28" />
</a>
<br />

<div class="clear-both"></div>

? };
