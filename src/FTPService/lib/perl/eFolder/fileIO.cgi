#!/usr/bin/perl
use lib qw(/opt/Embian/lib/perl/);
use eFolder::CONFIG; 
use eFolder::CONSTANT;
use eFolder::RESOURCE_ENG;
use eFolder::mCGI;
use eFolder::UserObject;
use POSIX qw(strftime);
use Time::HiRes;
use eFolder::Account;
use eFolder::IndexerSphinx;

use Apache2::RequestIO;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::Connection;

use APR::Socket;

use strict;

do_debug(">>>>>>>>>>>>>>>>>>>  fileIO.cgi is called >>>>>>>>>>>>>>>>>>>");

########## Main ##############################################
my ($strTargetPath, $LoadType, $lStartPosition) = ();
my $input = new eFolder::mCGI;
if(!$input->Parse()){
	printError(SessionNotFound);
	exit(1);
}

my $startTime =Time::HiRes::time();

my $objUser = new eFolder::UserObject;
my $strSessionId = $input->param("SessionId");

if($objUser->InitFromSession($strSessionId) != SUCCESS){
	do_debug("Session not found Error");
	printError(SessionNotFound);
	exit(1);
}

if($strSessionId =~ /^U[0-9]+/) {
	$strTargetPath= $input->param("TargetPath");
	#print STDERR "[JSLEE] TARGET PATH : $strTargetPath \n";
	$LoadType = $input->param("LoadType");		
	$lStartPosition = $input->param("StartPosition");
}else{
	printError(UnknownError);
	$objUser->Finalize();
	exit(1);
}

my $strRealPath = $objUser->GetRealPath($strTargetPath);
my $strUserName = $objUser->GetUserName();

my $client = $ENV{HTTP_USER_AGENT};
if( $client =~ /Downloader/){
	$client = "window";
}elsif( $client =~ /Uploader/){
	$client = "window";
}elsif( $client =~ /CFNetwork/){
	$client = "mac";
}

my $client_ip =  $ENV{REMOTE_ADDR};

if($LoadType eq "UPLOAD"){
 	if (!$objUser->IsOwner($strTargetPath)) {
            	$objUser->Finalize();
		printError(UnknownError);
		exit(1);
        }

	if(! $input->hasFileStream()){
		$objUser->Finalize();
		exit(1);
	}
	do_debug(">>>>>>>>>>>>>>>>>>>  upload start  >>>>>>>>>>>>>>>>>>>");
	my $httpFileStream = $input->GetStreamBuffer();
	FileUpload($strRealPath, $httpFileStream, $strUserName, $lStartPosition); 
	#print STDERR "After FileUpload \n";
	my $endTime =Time::HiRes::time();
	my $content1 = sprintf("%s %s [%s](%.2fs):[%s]:start=%d", 
		$strUserName, $LoadType, $client, $endTime-$startTime,$strTargetPath,$lStartPosition);
	do_debug($content1);

	my $objIndexer = eFolder::IndexerSphinx->new("localhost", 9312);
	#$objIndexer->DeleteFile($strTargetPath, $objUser);
	$objIndexer->FileUpload($strTargetPath, $objUser);

}elsif($LoadType eq "DOWNLOAD"){
	my $strVolumeName = $objUser->GetVolumeNameFromPath($strTargetPath);
	my $lActualSize = GetFileSize($strRealPath);
	my $lFileSize = $lActualSize - $lStartPosition + 1;
        if($lFileSize < 0) {
                printError(OS_ERROR, "File size is not match: $lFileSize ");
                $objUser->Finalize();
                exit(1);
        }

	if($strVolumeName ne "public"){
		if($strVolumeName  ne $objUser->GetUserName() || $strSessionId =~ /^S[0-9]+/) {
			if( !IsFreeCharge(2) ){
				if( $objUser->HasEnoughMoney_Local($lFileSize) eq 0){
					printError(NotEnoughMoney);	
					$objUser->Finalize();
					exit(1);
				}
			}
		}
	}
	my $strOrgPath = $strRealPath;

	my $strCacheFile = undef;
	do_debug(">>>>>>>>>>>>>>>>>>>  download start  >>>>>>>>>>>>>>>>>>>");

	my $lSendedLength = FileDownLoad($strRealPath, $strUserName, $lStartPosition, $strVolumeName, $strTargetPath, $client);
	my $endTime =Time::HiRes::time();
	my $diffTime = $endTime - $startTime;
	if ($diffTime == 0) {
		$diffTime = 0.01;
	}

	my $server_ip = $ENV{SERVER_ADDR};
	my $GroupName = (split(/\//, $strRealPath))[3];
	my @arr_group_kind = split(/\./, $server_ip);	
	my $traffic_state = "NORMAL";

	my $content =  sprintf("%s %s Speed=%dKB/sec:[%s][%s]:%dK+%dK(in %dK)(%.2fs) [Traffic State: %s][%s]", 
		$strUserName, $LoadType, $lSendedLength/$diffTime/1024,
		$strTargetPath, ($strCacheFile ? "CACHED" : ""),
		$lStartPosition/1024, $lSendedLength/1024, $lActualSize/1024, $diffTime,
		$traffic_state, $client);

	do_debug($content);	
}else{
	print "Content-Type:  text/html\n\n";
	print "Unknown Load Type: $LoadType";
}

$objUser->Finalize();


########## Start Procedure ####################################
sub IsFreeCharge{
	# 0 ==> no Free
	# 1 ==> Free for period
	# 2 ==> Free for all time
	my ($bFreeCode) = @_;
	my ($startTime, $endTime);

	if( !$bFreeCode ) {
		return 0;
	}elsif( $bFreeCode eq 1 ){
		my @arrTime = localtime();
		$startTime = START_FREE_TIME; $endTime = END_FREE_TIME;

		if( $arrTime[2] >= $startTime && $arrTime[2] <= $endTime) {	
			return 1;
		}
	}elsif( $bFreeCode eq 2 ){
		return 1;
	}
}

sub GetFileSize {
	my ($strFilePath) = @_;
	my $nSize = (stat($strFilePath))[7];
        return $nSize;
}

sub FileUpload{ 
	my ($strRealPath, $hStreamBuffer, $strUserName, $lStartPosition) = @_;
	my $Buffer = '';
	my $ret = 1;

	if($lStartPosition >0){
		if(!open(OUTPUT, ">> $strRealPath")){
			do_debug("File open Error : $strRealPath : $!");
			printError(OS_ERROR, $!);
			return;
		}
	}else{
		if(!open(OUTPUT, "> $strRealPath")){
			do_debug("File open Error : $strRealPath : $!");
			printError(OS_ERROR, $!);
			return;
		}
	}

	my $lReceivedData = 0;
	my $mod = 1; 
	while(defined($Buffer = $hStreamBuffer->ReadStream())){ 
		$lReceivedData = $lReceivedData + length($Buffer);
		
		if($Buffer ne ""){
			$ret = 	print OUTPUT $Buffer;
		}

		if($ret != 1){
			do_debug("Data write Error : $strRealPath : $!");
			last;
		}
	} 

	close(OUTPUT); 
	chmod (0644, $strRealPath);
	chown ($strUserName, $strUserName, $strRealPath); 
	printUploadOK();
}

sub printUploadOK{
 	print "Content-Type: text/html\n\n";
	print "<HTML><body>\n";
	print "UPLOAD: OK";
	print "</body></HTML>\n";
}

sub SocketClose {
	my $r = Apache2::RequestUtil->request;
	my $con = $r->connection;
	my $client_socket = $con->client_socket;
	$client_socket->close();
}

sub escape {
	my($toencode) = @_;
	$toencode=~s/([^a-zA-Z0-9_\-. ])/uc sprintf("%%%02x",ord($1))/eg;
	$toencode =~ tr/ /+/;	# spaces become pluses
	return $toencode;
}

sub printError{
	my($nErrorCode, $strErrorString) = @_;
 	print "Content-Type: text/html\n\n";
	print "<HTML><body>\n";
	print "ErrorCode: ".$nErrorCode . "<BR>\n";
	print "ErrorString: ". $strErrorString."<BR>\n";
	print "</body></HTML>\n";
	print STDERR "fileIO.cgi:: printError: $nErrorCode :  $strErrorString \n";
	SocketClose();
}

sub FileDownLoad{
	my ($strRealPath, $strUserName, $lStartPosition, $strTargetName, $strOrgPath, $client) = @_;

	my @arrPath = split(/\//, $strRealPath);
	my $FileName = $arrPath[$#arrPath];
	
	my ($ret, $lSendedLength) = (0,0);
	
	if(!open(INPUT, $strRealPath)){
		printError(OS_ERROR, $strOrgPath ." ". $!);
		return -1;
	}
	binmode INPUT;
	
	#my $lContentLength = GetFileSize($strRealPath) - $lStartPosition + 1;
	my $nFileSize = GetFileSize($strRealPath) ;
	my $lContentLength = $nFileSize - $lStartPosition;

	#print "Content-Type: application/octet-stream; name=\"$FileName\"\n";  # forces to download
	print "Content-Type: application/octet-stream \r\n";  # forces to download
#	print "Content-Type: application/x-msdownload; name=$FileName\n";  # forces to download
	print "Content-Length: ". $lContentLength."\r\n";

	$client =  $ENV{HTTP_USER_AGENT};
	if( $client =~ /MSIE/ ) { 
		$FileName = escape($FileName);
	}
	print "Content-Disposition: attachment; filename=\"$FileName\"\r\n\r\n";
#	print "Content-Disposition: inline; filename=$FileName\n\n";

	if($lStartPosition > 0){
		seek INPUT , $lStartPosition, 0;
	}

	$! = "";
	$| =1;
        my $RECORDSIZE= 8192 * 8;
	my $nDownComplete = 1;

	my $record; 
	my $myr = Apache2::RequestUtil->request ;

	until (eof(INPUT)) {
		read(INPUT, $record, $RECORDSIZE);
		#if($ret != 1){
		if($myr->connection->aborted){
			do_debug("$strUserName StopDownLoad:[$strOrgPath][$!]");
			$nDownComplete = 0;
			last;
		}
		eval{print $record};
		if ($@) {
			do_debug("$strUserName StopDownLoad:[$strOrgPath][$!]");
			$nDownComplete = 0;
			last;
		}

		$lSendedLength = $lSendedLength + length($record);
		$record = undef;
	}
	
	close(INPUT);
	return $lSendedLength;
}

