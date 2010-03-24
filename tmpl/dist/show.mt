? my ($dist, $files) = @_;
? use String::CamelCase qw/decamelize/;
? extends 'base.mt';
? block title => 'FrePAN page';
? block body_id => 'DistPage';
? block content => sub {

<h2><?= $dist->{name} ?></h2>

<table class="modulemeta">
<tr><th>This Release</th><td><span class="dist-name"><?= $dist->{name} ?></span>-<span class="dist-version"><?= $dist->{version} ?></span>
    [<a href="<?= $dist->{download_url} ?>">Download</a>]
    [<a href="/src/<?= uc $dist->{author} ?>/<?= $dist->{name} ?>-<?= $dist->{version} ?>/">Browse</a>]
</td>
<tr><th>Author</th><td><a href="http://search.cpan.org/~<?= lc $dist->{author} ?>/"><?= $dist->{author} ?></a></td></tr>
<tr><th>Links</th><td>[<a href="http://rt.cpan.org/NoAuth/Bugs.html?Dist=<?= $dist->{name} ?>">View/Report Bugs</a>] [ <a href="http://deps.cpantesters.org/?module=<?= $dist->{name} ?>;perl=latest">Dependencies</a> ] [ <a href="http://search.cpan.org/~<?= lc $dist->{author} ?>/<?= $dist->{name} ?>-<?= $dist->{version} ?>">search.cpan.org</a> ]</td></tr>
? for my $meth (qw/repository homepage bugtracker/) {
?  if (my $var = $dist->{$meth}) {
<tr><th><?= $meth ?></th><td><?= $var ?></td></tr>
?  }
? }
?  if (my $var = $dist->{license}) {
<tr><th>License</th><td><a href="<?= $var ?>"><?= +{'http://dev.perl.org/licenses/' => 'Perl'}->{$var} || $var ?></a></td></tr>
?  }
<tr><th>Special Files</th><td>
? for my $fname (qw/MANIFEST Makefile.PL Build.PL Changes ChangeLog META.yml META.json/) {
?  (my $key = 'has_' . decamelize($fname)) =~ s/[.]/_/g;
?  if ( $dist->{$key} ) {
    <a href="/src/<?= uc($dist->{author}) ?>/<?= $dist->{name} ?>-<?= $dist->{version} ?>/<?= $fname ?>"><?= $fname ?></a>
?  }
? }
</td></tr>
<tr><th>Released</th><td>
    <?= $dist->{released_date} ?>
</td></tr>
</table>


<img src="<?= $dist->{gravatar_url} ?>" width="80" height="80" class="gravatar" />
<div class="clear-both">&nbsp;</div>

<table class="package-list">
<tr>
    <th>package</th>
    <th>description</th>
</tr>
? for my $file (@{$dist->{files}}) {
    <tr>
? if ($file->{has_html}) {
        <td><a href="/~<?= lc $dist->{author} ?>/<?= $dist->{name} ?>-<?= $dist->{version} ?>/<?= $file->{path} ?>"><?= $file->{package} ?></a></td>
? } else {
        <td><?= $file->{package} ?></td>
? }
        <td><?= $file->{description} ?></td>
    </tr>
? }
</table>

? };
