#!/usr/bin/perl

###############################################################
# < eFolderSystemCheck.pl > 
#
# Required Package : SOAP::Lite, HTTP::Lite
###############################################################

use strict;
use SOAP::Lite;
use HTTP::Lite;
print "\n";
#use SOAP::Lite +xmlschema=>'2001', +trace=>'debug';

###### Test Configuration ######

### SOAP TEST ###

my $proxyFTPService = "http://f01dev.innomp3.com/FTPService";
my $nsFTPService = "http://wwwdev.FTPService.gnu/FTPService";
my $proxyEAMService = "http://eamdev.innomp3.com:6789/EAM";
my $nsEAMService = "http://wwwdev.eam.gnu/EAM";

my @arrSOAPns = ($nsFTPService, $nsEAMService);
my @arrSOAPproxy = ($proxyFTPService, $proxyEAMService);

### CGI TEST ###
my $cgiF01 = "http://f01dev.innomp3.com/IO/test_page.cgi";

### HTTP TEST ###
my $httpF01 = "http://f01dev.innomp3.com/test_page.html";
my $httpF01Empty = "http://f01dev.innomp3.com/";

my $httpEAM = "http://eamdev.innomp3.com:6789/test_page.html";
my $httpEAMEmpty = "http://eamdev.innomp3.com:6789/";

my $httpWWW = "http://wwwdev.innomp3.com/test_page.html";
my $httpWWWEmpty = "http://wwwdev.innomp3.com/";

my $httpStream = "http://streamdev.innomp3.com/test_page.html";
my $httpStreamEmpty = "http://streamdev.innomp3.com/";

my @arrURLs = ($httpWWW, $httpWWWEmpty, $httpEAM, $httpEAMEmpty, $httpF01, $httpF01Empty, $httpStream, $httpStreamEmpty);

################################


## SOAP TEST ##
print "### SOAP TEST ### \n";


for( my $i = 0 ; $i < 2 ; $i++){
	my $hSoap = new  SOAP::Lite->ns($arrSOAPns[$i])->proxy($arrSOAPproxy[$i]);
	print "\nSERVER: $arrSOAPproxy[$i] \n";
	print $hSoap->hi()->result;
	print "\n\n";
}
### CGI TEST ###

print "### CGI TEST ### \n";
print "CGI SERVER: $cgiF01 \n";

my $http = new HTTP::Lite;
my $req = $http->request($cgiF01) or die "Unable to get document: $!";
print $http->body();
print "\n\n";

### HTTP TEST ###
sub CheckHTTPResult {

	my $code = shift;
	my $URL = shift;
	if( !defined($code)){
		print "URL: [ $URL ] is Wrong URL!! \n";
	}elsif( $code == 400){
		print "RESULT CODE: [ $code ][ Bad Request! : The request had bad syntax or was inherently impossible to be satisfied. ] \n";
	}elsif( $code == 404){
		print "RESULT CODE: [ $code ][ URL Not Found: The server has not found anything matching the URI given ] \n";
	}elsif( $code == 403){
		print "RESULT CODE: [ $code ][ URL Access Denied : The request is for something forbidden. Authorization will not help.] \n";
	}elsif( $code == 500){
		print "RESULT CODE: [ $code ][ Internal Error: The server encountered an unexpected condition which prevented it from fulfilling the request. ] \n";
	}elsif( $code == 200){
		print "RESULT CODE: [ $code ][ URL is Fine~!! Good!! ] \n";
	}else{
		print "RESULT CODE: [ $code ][ Another Code.. ] \n";
	}



}

print "### HTTP TEST ### \n";

foreach my $URL (@arrURLs) {
	print "\nHTTP SERVER : $URL \n";
	$req = $http->request($URL) ;
	CheckHTTPResult($req, $URL);
}


