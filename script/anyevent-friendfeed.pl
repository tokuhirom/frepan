#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use FrePAN;
use FrePAN::Script::FriendFeed;

my $c = FrePAN->bootstrap();
FrePAN::Script::FriendFeed->new()->run();

