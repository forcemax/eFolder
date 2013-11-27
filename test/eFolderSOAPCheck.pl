#!/usr/bin/perl

###############################################################
# < eFolderSystemCheck.pl > 
#
# Required Package : SOAP::Lite
###############################################################

use strict;
use SOAP::Lite;
print "\n";
#use SOAP::Lite +xmlschema=>'2001', +trace=>'debug';

###### Test Configuration ######

### SOAP TEST ###

my $proxyFTPService = "http://f01dev.embian.com/FTPService";
my $nsFTPService = "http://wwwdev.FTPService.gnu/FTPService";

my @arrSOAPns = ($nsFTPService);
my @arrSOAPproxy = ($proxyFTPService);

################################


## SOAP TEST ##
print "### SOAP TEST ### \n";


for( my $i = 0 ; $i <= $#arrSOAPns ; $i++){
	my $hSoap = new  SOAP::Lite->ns($arrSOAPns[$i])->proxy($arrSOAPproxy[$i]);
	print "\nSERVER: $arrSOAPproxy[$i] \n";
	print $hSoap->hi()->result;
	print "\n\n";
}

