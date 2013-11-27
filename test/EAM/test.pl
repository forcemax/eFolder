#!/usr/bin/perl

use Data::Dumper;

my @arrItem = getpwnam("inno");

print Dumper(@arrItem) . "\n";


