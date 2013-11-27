#!/usr/bin/perl -w 
use MIME::Lite;

my $msg = new MIME::Lite(
	From 	=> '박현진<hjpark@embian.com>',
	To	=> 'hjpark@embian.com',
	Subject => '박현진이다',
	Type 	=> 'multipart/alternative');

my $plain = $msg->attach(Type=>'text/plain',
			 Data=> "My wonderful world");

my $fancy = $msg->attach(Type=>'multipart/related');

$fancy->attach(Type=>'text/html',
		Data=>'<html><body> <h1> himan </h1> </body></html>');

$msg->send;
