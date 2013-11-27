#!/usr/bin/perl
use strict;
use eFolder::DNSLib;

########## Main ##############################################
#my $DNSLib = new eFolder::DNSLib("*",1);
my $DNSLib = new eFolder::DNSLib("LA",1);

sub ReturnError {
	my ($nErrCode, $strErrString) = @_;
	my $errString = sprintf("ERROR(%s): %s\n", $nErrCode, $strErrString);
	print "Content-Type: text/plain\n\n";
	print $errString, "\n";
	print "{EMEND}";
	exit;
}


#if (! $DNSLib->GetHost()) { // Function pointer error@!!
if (! $DNSLib->_GetHostLA()) {
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
		ReturnError($DNSLib->{nErrCode}, $DNSLib->{strErrString});
	}
}

########## Start Procedure ####################################
print "Content-Type: text/plain\n\n";

my $ref_arrKey = $DNSLib->{REF_ARRKEY};
my $i = 0;
for( $i = 0; $i <= $#$ref_arrKey; $i++ ){
	print $$ref_arrKey[$i].":".$DNSLib->{$$ref_arrKey[$i]}. "\n";
}

print "{EMEND}";
