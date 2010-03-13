? my ($dist, $file) = @_;
? extends 'base.mt';
? block title => 'FrePAN page';
? block body_id => 'PodPage';
? block content => sub {

<div class="blead-list">
<a href="http://search.cpan.org/~<?= lc($dist->author) ?>"><?= $dist->author ?></a> &gt;
<a href="/~<?= lc $dist->author ?>/<?= $dist->name ?>-<?= $dist->version ?>/"><?= $dist->name ?>-<?= $dist->version ?></a> &gt;
<?= $file->path ?>
</div>

<div class="source"><a href="/src/<?= uc $dist->author ?>/<?= $dist->name ?>-<?= $dist->version ?>/<?= $file->path ?>">SOURCE</a></div>

<div class="pod"><?= encoded_string($file->html) ?></div>

? };
