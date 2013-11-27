#!/usr/bin/perl -w 
use MIME::Lite;

my $msg = new MIME::Lite(
	From 	=> '������<hjpark@embian.com>',
	To	=> 'hjpark@embian.com',
	Subject => '�������̴�',
	Type 	=> 'multipart/alternative');

my $plain = $msg->attach(Type=>'text/plain',
			 Data=> "My wonderful world");

my $fancy = $msg->attach(Type=>'multipart/related');

$fancy->attach(Type=>'text/html',
		Data=>'<html><body> <h1> himan </h1> </body></html>');

$msg->send;
