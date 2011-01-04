use strict;
use warnings;
use Test::More;
use Pod::POM;
use FrePAN::Pod::POM::View::HTML;

my $parser = Pod::POM->new();
my $pom = $parser->parse_text(<<'...') or die;
=head1 SEE ALSO

L<Acme::PrettyCure>
...
my $html = FrePAN::Pod::POM::View::HTML->print($pom);
is $html, <<'...';
<h1>SEE ALSO</h1>

<p><a href="/perldoc?Acme%3A%3APrettyCure">Acme::PrettyCure</a></p>
...

done_testing;

