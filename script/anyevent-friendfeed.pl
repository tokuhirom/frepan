#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use local::lib "$FindBin::Bin/../extlib/";
use FrePAN;
use FrePAN::Script::FriendFeed;

my $c = FrePAN->bootstrap();
FrePAN::Script::FriendFeed->new()->run();

