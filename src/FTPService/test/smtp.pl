#!/usr/bin/perl -w
use Net::SMTP;

$smtp = Net::SMTP->new('localhost');

$smtp->mail('hjpark');
$smtp->to('hjpark@embian.coom');

$smtp->data();
$smtp->datasend("hi man");
$smtp->dataend();
$smtp->quit;

