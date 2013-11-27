#!/usr/bin/perl
use strict;
use AFS getvolstats;

$path = "/afs/embian.gnu/home/hjpark";
$stats = getvolstats($path);
foreach $key (sort keys %$stats) {
  printf("%20s  %s\n",$key, $$stats{$key});
}
