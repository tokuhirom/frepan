? my ($author, $packages) = @_;
? extends 'base.mt';
? block body_id => 'RootPage';
? block title => 'FrePAN';
? block content => sub {

<h1><?= $author->fullname ?></h1>
<img src="<?= email2gravatar_url($author->email) ?>" alt="<?= $author->fullname ?>" />

<table>
<tr>
    <th>Distribution</th>
    <!-- <th>Abstract</th> -->
    <th>Released</th>
</tr>
? for my $dist (@$packages) {
<tr>
    <td><?= $dist->{dist_name} ?>-<?= $dist->{dist_version} ?></td>
    <!-- <td><?= $dist->{abstract}  ?></td> -->
    <td><?= $dist->{released} ?></td>
</tr>
? }
</table>

? };
