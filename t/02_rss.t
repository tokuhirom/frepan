use strict;
use warnings;
use utf8;
use Test::More;
use FrePAN2;
use File::Spec;

chdir File::Spec->rootdir;

my $c = FrePAN2->new();
like $c->xslate->render('html.tt'), qr{<!doctype html>};

done_testing;

