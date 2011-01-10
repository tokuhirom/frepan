#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../extlib/lib/perl5/";
use FrePAN;
use FrePAN::Script::FriendFeed;

my $c = FrePAN->bootstrap();
FrePAN::Script::FriendFeed->new()->run();

