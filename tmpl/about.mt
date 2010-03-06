? my ($dists, $page, $has_next) = @_;
? extends 'base.mt';
? block body_id => 'RootPage';
? block title => 'About FrePAN';
? block content => sub {

<h2>about FrePAN</h2>

<p>
This site gets tar ball from fresh mirror, and rendering pod.
You can get the new CPAN module information realtime!
</p>

<p>
If you want to get the non-fresh cpan modules, please use <a href="http://search.cpan.org/">search.cpan.org</a> instead.
</p>

<h2>SEE ALSO</h2>

<h3>cpanf</h3>
<p>
    <a href="http://search.cpan.org/dist/App-CPAN-Fresh/">cpanf</a>
    get and install CPAN modules from fresh mirror.
</p>

<h3>friendfeed.com/cpan</h3>
<p>
    <a href="http://friendfeed.com/cpan">friendfeed.com/cpan</a>
    publishes realtime CPAN uploads information.
    This bot gets information from cpantesters fresh mirror.
</p>

? };
