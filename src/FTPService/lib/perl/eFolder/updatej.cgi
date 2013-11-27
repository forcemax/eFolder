#!/usr/bin/perl
use strict;
use eFolder::DNSLib;

########## Main ##############################################
my $DNSLib = new eFolder::DNSLib("*",1);
#my $DNSLib = new eFolder::DNSLib("LA",1);

sub ReturnError {
	my ($nErrCode, $strErrString) = @_;
	my $errString = sprintf("ERROR(%s): %s\n", $nErrCode, $strErrString);
	print "Content-Type: text/plain\n\n";
	print $errString, "\n";
	print STDERR $strErrString;
	print "{EMEND}";
	exit;
}


if (! $DNSLib->GetJavaUpdateState()) {
	if ($DNSLib->{nErrCode} == -100 ||
		$DNSLib->{nErrCode} == -200) {
		sleep(1);
		if (!$DNSLib->GetHost()) {
			ReturnError($DNSLib->{nErrCode}, $DNSLib->{strErrCode});
		}
		if (!$DNSLib->{DOWN_IP}) {
			ReturnError("-400", "IP not found even with _GetHostAny!");
		}
	} else {
		ReturnError($DNSLib->{nErrCode}, $DNSLib->{strErrCode});
	}
}else{
	print "Content-Type: text/plain\n\n";
	if($DNSLib->{UPDATESTATE} eq "PASS"){
	        print "EMSTATE:".$DNSLib->{UPDATESTATE}. "\n";
		print "{EMEND}";
		exit;
	}
}

########## Start Procedure ####################################
print "EMSTATE:".$DNSLib->{UPDATESTATE}. "\n";
print "EMUPDATE:".$DNSLib->{UPDATEIP}. "\n";
print "{EMEND}";
