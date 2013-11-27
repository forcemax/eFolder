#!/usr/bin/perl 
package eFolder::FTPServiceMain;
use strict;

use eFolder::CONFIG;
use eFolder::CONSTANT;
use eFolder::RESOURCE_ENG;

#use SOAP::Lite +trace=>"debug";
use SOAP::Lite;
use eFolder::UserObject;
use eFolder::FileSystem;
use eFolder::SOAPHelper;
use Text::Iconv;
use eFolder::Session;
use eFolder::FileFinder;
use eFolder::IndexerSphinx;
use Time::Local;
use Time::HiRes qw( time gettimeofday tv_interval);
use POSIX qw(strftime);
use MIME::Base64 qw(encode_base64);
use Data::Dumper;

#_initConfiguration();

#sub _initConfiguration {
#    if( !defined (G_DEBUG_RUN)){
#        print STDERR "[eFolder] First ReadConfiguration()\n";
#        ReadConfiguration();
#    }
#}

sub hi{
	my($class,@arg) = @_;
        return strftime("[eFolder] %Y-%m-%d %H:%M:%S", localtime());
}


sub echo{
	my($class, @arg) = @_;

	@arg = map {
                $_=SOAP::Data->type(string=>$_);
        } @arg;
                                        
	my $objSOAPHelper  = new eFolder::SOAPHelper;
        if($#arg != -1){
                return $objSOAPHelper->MakeEchoResponse(\@arg);
        }else{
                ReturnError(EmptyData);
        }
}

sub FixEncoding{
	my $string = shift;

    	my $buf = "";
	open (MEM, ">", \$buf);
	print MEM $string;
	close(MEM);

	$string = pack "U0C*", unpack "C*", $buf;
	$buf = pack "C*", unpack "U0C*", $string;
	
	return $buf;
}


sub ReturnError{
        my(@arrError) = @_;
        if ($arrError[0] ne "1008")  {   # Ignore EmptyData
		do_debug( 
			sprintf("[%s][ReturnError:%s]:%s(%s)\n",
                	strftime("%Y-%m-%d %H:%M:%S", localtime()),
                	$arrError[0], 
			$arrError[1],
			$arrError[2]));
        }
        die SOAP::Fault->faultcode("SOAP-ENV:".$arrError[0])
                        ->faultstring($arrError[1]);
}


sub SessionCheck{
	my($class, @arrUser) = @_;

	do_debug("=======================");
	do_debug("execute...");

	do_debug("Parameter [arrUser : " . join(",", @arrUser));
	my $objUser = new eFolder::UserObject;
	if($objUser->InitFromSession(@arrUser) !=SUCCESS){
		do_debug("Session not found Error");
		$objUser->Finalize();
		ReturnError(SessionNotFound, $arrUser[0]);
	}
	do_debug("Success...");
}

sub Authenticate3{
        my($class, @arrUser)  = @_;
	
	do_debug("=======================");
	do_debug("execute...");
        
	do_debug("Parameter [arrUser : " . join(",", @arrUser));
	my $objUser = new eFolder::UserObject;
        my %objUserProfile;

        my $startTime =Time::HiRes::time();

        if($objUser->Init(@arrUser) != SUCCESS){
		do_debug("Version conflict Error");
                ReturnError(VersionConflict,"$arrUser[0]");
        }

         if($objUser->CheckUAS($arrUser[0]) != SUCCESS) {
		do_debug("User not found Error");
                $objUser->Finalize();
                ReturnError(AuthenticationFail,"$arrUser[0]");
        }

        my $GroupCode = $objUser->{GroupCode};
	
	do_debug("GROUPCODE: $GroupCode \n");

        if($objUser->Authenticate() != SUCCESS){
		do_debug("Authenticate fail Error");
                $objUser->Finalize();
                ReturnError(AuthenticationFail, "$arrUser[0]");
        }
       	
#        my $nAdultAuth = $objUser->CheckAdultAuthenticate($arrUser[0]);
	# Pass Adult Auth
	my $nAdultAuth = 1;

        if( !defined($nAdultAuth) ){
                $nAdultAuth = 0 ;
        }
        $objUser->Finalize();


        my $objSession = new eFolder::Session;
        my $strSessionID = $objSession->AddUserSession2(@arrUser, $nAdultAuth);
        if(!defined($strSessionID)){
		do_debug("Create session fail Error");
                $objSession->Finalize();
                ReturnError(CreateSessionFail, "$arrUser[0]");
        }
        $objSession->Finalize();

        my $endTime =Time::HiRes::time();

	my $client =  $ENV{HTTP_USER_AGENT};
	if( $client =~ /Window/){
        	$client = "window";
	}elsif( $client =~ /Mac/){
        	$client = "mac";
	}elsif( $client =~ /gSOAP/){
        	$client = "weblink";
	}

        my $param = sprintf("%s[%s][%s] Login,RunTime:%.2fsec CLIENT_VERSION-->%s",$arrUser[0],$ENV{REMOTE_ADDR},$client, $endTime - $startTime, $arrUser[2]);
        do_debug($param);

        my $preAdult = "";
        my $strNewSessionID = $strSessionID;

        if ($nAdultAuth eq 0){
                $preAdult = "D";
        }elsif($nAdultAuth eq 1 ||  $nAdultAuth eq 3 ){
                $preAdult = "C";
        }else{
                $preAdult = "A";
        }

        $strNewSessionID = $GroupCode . $preAdult . $strSessionID;

	do_debug("SESSIONID : ".$strNewSessionID);
	do_debug("Success...");
        return $strNewSessionID;
}

sub ChangePassword{
	my($class, $strNewPassword, @arrUser) = @_;

	do_debug("=======================");
	do_debug("execute...");
	
	do_debug("Parameter [newpassword : " . $strNewPassword . ", arrUser : " . join(",", @arrUser));
	my $objUser = new eFolder::UserObject;
	if($objUser->InitFromSession(@arrUser) != SUCCESS) {
		do_debug("Session not found Error");
		$objUser->Finalize();
		ReturnError(SessionNotFound,,"$arrUser[0]");
	}

	if($objUser->CheckUAS() != SUCCESS) {
		do_debug("User not found Error");
		$objUser->Finalize();
		ReturnError(AuthenticationFail,"$arrUser[0]");
	}

	# 2005.10.24 goodjs : blank in Password is delete
	do_debug("NewPassword Before remove blank : [$strNewPassword]");
	$strNewPassword =~ s/ //g;
	do_debug("NewPassword After remove blank : [$strNewPassword]");
	
	# 2005.08.22 goodjs : Password length limitation 4 - 12
	my $nLen = length($strNewPassword);
	do_debug("Password length : $nLen, $strNewPassword");

	if( 4 > $nLen || 12 < $nLen) {
		do_debug("Invalid password length Error");
		$objUser->Finalize();
		ReturnError(InvalidPasswdLength, "$arrUser[0]");
	}

	####
	$strNewPassword = FixEncoding($strNewPassword);
	if ($strNewPassword eq "") {
		do_debug("Invalid character after FixEncoding");
		ReturnError(IconvFail, "at ChangePassword by $arrUser[0]");
	}
	if($objUser->ChangePassword($strNewPassword) != SUCCESS){
		do_debug("Change password fail Error");
		$objUser->Finalize();
		ReturnError(ChangePasswordFail, "$arrUser[0]");
	}

	$objUser->Finalize();

	do_debug("Success...");
	return SUCCESS;
}


sub MakeDirectoryAll{
	my ($class, $strTargetDirectory, @arrUser) = @_;
	
	do_debug("=======================");
	do_debug("execute...");

	do_debug("Parameter [targetpath : " . $strTargetDirectory . ", arrUser : " . join(",", @arrUser));
	my $objUser = new eFolder::UserObject;
	if($objUser->InitFromSession(@arrUser) !=SUCCESS){
		do_debug("Session not found Error");
		$objUser->Finalize();
		ReturnError(SessionNotFound,"$arrUser[0]");
	}
	if($objUser ->CheckUAS() != SUCCESS ){
		do_debug("User not found Error");
		$objUser->Finalize();
		ReturnError(AuthenticationFail,"$arrUser[0]");
	}

       if (!$objUser->IsOwner($strTargetDirectory)) {
		do_debug("Permission denied Error");
                $objUser->Finalize();
                ReturnError(PermissionDenied, $objUser->{strUserName} . "=>" . $strTargetDirectory);
        }

	$strTargetDirectory = FixEncoding($strTargetDirectory);
	if ($strTargetDirectory eq "") {
		do_debug("Invalid character after FixEncoding");
		ReturnError(IconvFail, "MakeDiretory");
	}
	my $strRealPath = $objUser->GetRealPath($strTargetDirectory);

	my $objFileSystem = new eFolder::FileSystem;
	if( $objFileSystem->MakeDirectoryAll($strRealPath) !=SUCCESS){
		do_debug("Make directory fail Error");
		$objUser->Finalize();
		ReturnError($objFileSystem->GetError());
	}

	$objUser->Finalize();
	do_debug("Success...");
	return SUCCESS;
}

sub MakeDirectory{
	my ($class, $strTargetDirectory, @arrUser) = @_;
	
	do_debug("=======================");
	do_debug("execute...");

	do_debug("Parameter [targetpath : " . $strTargetDirectory . ", arrUser : " . join(",", @arrUser));
	my $objUser = new eFolder::UserObject;
	if($objUser->InitFromSession(@arrUser) !=SUCCESS){
		do_debug("Session not found Error");
		$objUser->Finalize();
		ReturnError(SessionNotFound,"$arrUser[0]");
	}
	if($objUser ->CheckUAS() != SUCCESS ){
		do_debug("User not found Error");
		$objUser->Finalize();
		ReturnError(AuthenticationFail,"$arrUser[0]");
	}

       if (!$objUser->IsOwner($strTargetDirectory)) {
		do_debug("Permission denied Error");
                $objUser->Finalize();
                ReturnError(PermissionDenied, $objUser->{strUserName} . "(MakeDirectory)=>" . $strTargetDirectory);
        }


	$strTargetDirectory = FixEncoding($strTargetDirectory);
	if ($strTargetDirectory eq "") {
		do_debug("Invalid character after FixEncoding");
		ReturnError(IconvFail, "MakeDiretory");
	}
	my $strRealPath = $objUser->GetRealPath($strTargetDirectory);

	if( $strRealPath =~ /\.\.$/){
		do_debug("Invalid character after GetRealPath");
		ReturnError(WrongFileName);
	}

	my $objFileSystem = new eFolder::FileSystem;
	if( $objFileSystem->MakeDirectory($strRealPath) !=SUCCESS){
		do_debug("Make directory fail Error");
		$objUser->Finalize();
		ReturnError($objFileSystem->GetError());
	}

	$objUser->Finalize();
	do_debug("Success...");
	return SUCCESS;
}

sub DeleteDirectory{
	my($class, $strTargetDirectory, @arrUser) = @_;
	
	do_debug("=======================");
	do_debug("execute...");
	
	do_debug("Parameter [targetpath : " . $strTargetDirectory . ", arrUser : " . join(",", @arrUser));
	my $startTime =Time::HiRes::time();
	my $objUser = new eFolder::UserObject;

	if($objUser->InitFromSession(@arrUser) !=SUCCESS){
		do_debug("Session not found Error");
		$objUser->Finalize();
		ReturnError(SessionNotFound,"$arrUser[0]");
	}
	my $nResult = $objUser->CheckUAS();
	if($nResult !=SUCCESS){
		do_debug("User not found Error");
		$objUser->Finalize();
		ReturnError(AuthenticationFail,"$arrUser[0]");
	}
        if (!$objUser->IsOwner($strTargetDirectory)) {
		do_debug("Permission denied Error");
                $objUser->Finalize();
                ReturnError(PermissionDenied, $objUser->{strUserName} . "(DeleteDirectory)=>" . $strTargetDirectory);
        }

	$strTargetDirectory = FixEncoding($strTargetDirectory);
	if ($strTargetDirectory eq "") {
		do_debug("Invalid character after FixEncoding");
		ReturnError(IconvFail, "DeleteDirectory");
	}

	my $strRealPath = $objUser->GetRealPath($strTargetDirectory);

        my @filepath = split(/\:/, $strTargetDirectory);
        if ($filepath[0] eq $objUser->{strUserName} || $filepath[0] eq "Home") {
                # DO Nothing
        } else {
		if( !$objUser->IsAdmin() && !$objUser->IsGroup($filepath[0]) ){
			do_debug("Permission denied Error");
                        ReturnError(PermissionDenied, $objUser->{strUserName} . "(DeleteDirectory)=>" . $strTargetDirectory);
                }

#                ReturnError(PermissionDenied, $objUser->{strUserName} . "(DeleteDirectory)=>" . $strTargetDirectory);
	}
    
	my $objFileSystem = new eFolder::FileSystem;
	$nResult = $objFileSystem->DeleteDirectory($strRealPath);

	if($nResult !=SUCCESS){
		do_debug("Delete directory fail Error");
		$objUser->Finalize();
		ReturnError($objFileSystem->GetError());
	}

	my $endTime =Time::HiRes::time();
	
	my $param = sprintf("%s DeleteDirectory :RUN TIME: %.2fsec:[%s]",$objUser->{strUserName},$endTime - $startTime, $strTargetDirectory);
	do_debug($param);

	my $objIndexer = eFolder::IndexerSphinx->new("localhost", 9312);
    	$objIndexer->DeleteDirectory($strTargetDirectory, $objUser);

	$objUser->Finalize();
	do_debug("Success...");
	return $nResult;
}

sub DeleteFile{
	my ($class, $strTargetFile, @arrUser) = @_;
	
	do_debug("=======================");
	do_debug("execute...");
	
	do_debug("Parameter [targetpath : " . $strTargetFile . ", arrUser : " . join(",", @arrUser));
	my $startTime =Time::HiRes::time();
	my $objUser = new eFolder::UserObject;
	if($objUser->InitFromSession(@arrUser) !=SUCCESS){
		do_debug("Session not found Error");
		$objUser->Finalize();
		ReturnError(SessionNotFound,"$arrUser[0]");
	}
	my $nResult = $objUser->CheckUAS();

	if($nResult != SUCCESS){
		do_debug("User not found Error");
		$objUser->Finalize();
		Return Error(AuthenticationFail,"$arrUser[0]");
	}

	if (!$objUser->IsOwner($strTargetFile)) {                
		do_debug("Permission denied Error");
		$objUser->Finalize();
		ReturnError(PermissionDenied, $objUser->{strUserName} . "(DeleteFile)=>" . $strTargetFile);
	}
	
	$strTargetFile = FixEncoding($strTargetFile);
	if ($strTargetFile eq "") {
		do_debug("Invalid character after FixEncoding");
		ReturnError(IconvFail, "DeleteFile");
	}

	my @filepath = split(/\:/, $strTargetFile);
	my $strRealPath = $objUser->GetRealPath($strTargetFile);
        if ($filepath[0] eq $objUser->{strUserName} || $objUser->{strUserName} eq "Home" || $filepath[0] eq "Home") {
                # DO Nothing
        } else {
        	if( !$objUser->IsAdmin() && !$objUser->IsGroup($filepath[0]) ){
			do_debug("Permission denied Error");
                        ReturnError(PermissionDenied, $objUser->{strUserName} . "(DeleteFile)=>" . $strTargetFile);
                }

	}
	my $objFileSystem = new eFolder::FileSystem;
	$nResult = $objFileSystem->DeleteFile($strRealPath);

	if($nResult != SUCCESS){
		do_debug("Delete file fail Error");
		$objUser->Finalize();
		ReturnError($objFileSystem->GetError());
	}
	my $endTime =Time::HiRes::time();
	
	my $param = sprintf("RUN TIME:%.2fsec:[%s]",$endTime - $startTime, $strTargetFile);
	do_debug($param);

	my $objIndexer = eFolder::IndexerSphinx->new("localhost", 9312);
    	$objIndexer->DeleteFile($strTargetFile, $objUser);

	$objUser->Finalize();
	do_debug("Success...");
	return $nResult;
}


sub Rename{
	my ($class, $strOldPath, $strNewPath, @arrUser) = @_;
	
	do_debug("=======================");
	do_debug("execute...");
	
	do_debug("Parameter [oldpath : " . $strOldPath . ", newpath : " . $strNewPath . ", arrUser : " . join(",", @arrUser));
	my $objUser = new eFolder::UserObject;
	if($objUser->InitFromSession(@arrUser) !=SUCCESS){
		do_debug("Session not found Error");
		$objUser->Finalize();
		ReturnError(SessionNotFound,"$arrUser[0]");
	}
	my $nResult = $objUser->CheckUAS();
	if($nResult != SUCCESS){
		do_debug("User not found Error");
		$objUser->Finalize();
		ReturnError(AuthenticationFail,"$arrUser[0]");
	}

        if (!$objUser->IsOwner($strOldPath)) {
		do_debug("Permission denied Error");
                $objUser->Finalize();
                ReturnError(PermissionDenied, $objUser->{strUserName} . "(Rename)=>" . $strOldPath);
        }


	$strOldPath = FixEncoding($strOldPath);
	if ($strOldPath eq "") {
		do_debug("Invalid character after FixEncoding");
		ReturnError(IconvFail, "at Rename strOldPath");
	}
	$strNewPath = FixEncoding($strNewPath);
	if ($strNewPath eq "") {
		do_debug("Invalid character after FixEncoding");
		ReturnError(IconvFail, "at Rename strNewPath");
	}

	my $strRealOldPath = $objUser->GetRealPath($strOldPath);
	my $strRealNewPath = $objUser->GetRealPath($strNewPath);
	
	if( $strRealNewPath =~ /\.\.$/){
		do_debug("Invalid character after GetRealPath");
		ReturnError(WrongFileName);
	}

	my $objFileSystem = new eFolder::FileSystem;
	$nResult = $objFileSystem->Rename($strRealOldPath, $strRealNewPath);

	if($nResult != SUCCESS) {
		do_debug("Rename fail Error");
		$objUser->Finalize();
		ReturnError($objFileSystem->GetError());
	}

	my $objIndexer = eFolder::IndexerSphinx->new("localhost", 9312);
        $objIndexer->Rename($strOldPath, $strNewPath,$objUser);

	$objUser->Finalize();
	do_debug("Success...");
	return $nResult;
}

sub ListDirectory3{
	my ($class, $strDirectory, @arrUser) = @_;
	
	do_debug("=======================");
	do_debug("execute...");
	
	do_debug("Parameter [targetpath : " . $strDirectory . ", arrUser : " . join(",", @arrUser));
	my @arrDirectoryList=();
	my $strFileName = "";
	
	my $startTime =Time::HiRes::time();

	my $objUser = new eFolder::UserObject;
	if($objUser->InitFromSession(@arrUser) !=SUCCESS){
		do_debug("Session not found Error");
		$objUser->Finalize();
		ReturnError(SessionNotFound, $arrUser[0]);
	}
		
	$strDirectory = FixEncoding($strDirectory);

	if ($strDirectory eq "") {
		do_debug("Invalid character after FixEncoding");
		ReturnError(IconvFail, "at ListDirectory3");
	}

	#my $TargetID = (split(/:/, $strDirectory))[0];
	my $TargetID = $objUser->{strUserName} ;
	do_debug("TARGET ID: $TargetID");

	my $nAdult = $objUser->{bAdultAuth};
	do_debug("Adult:".$nAdult);

	my $nResult = $objUser->CheckUAS($TargetID);
	my $GroupCode = $objUser->{GroupCode};

	do_debug("LS GROUP : $GroupCode");

	if($nResult != SUCCESS){
		do_debug("User not found Error");
		$objUser->Finalize();
		ReturnError(AuthenticationFail, $arrUser[0]);
	}

	if( $objUser->HasRight($strDirectory) eq 0){
		do_debug("Permission denied Error");
		$objUser->Finalize();
		ReturnError(PermissionDenied , $objUser->{strUserName} . "(ListDirectory3)=>" . $strDirectory);
	}


	#print STDERR "strDirectory = $strDirectory \n";
	my $strRealPath = $objUser->GetRealPath($strDirectory);
	if(!defined($strRealPath)){
		do_debug("Invalid character after GetRealPath");
		$objUser->Finalize();
		ReturnError(EmptyData);
	}
	my $strTargetName = $objUser->GetVolumeNameFromPath($strDirectory) ;
	my $IsMine = 0;
	
	if($strTargetName eq $objUser->{strUserName}) { $IsMine = 1; }
	
	$strRealPath =~ s/\/\//\//g;
	my @arrItem = split(/\//, $strRealPath);
	my $position = @arrItem;
	my $pathname = $arrItem[$position];	
	if ($pathname eq "") {
		$pathname = $arrItem[$position - 1];
	}

	do_debug("TARGET:$strTargetName, RealPath:$strRealPath, pathname:$pathname,  USER:$objUser->{strUserName}");

	if(encode_base64($pathname,"") eq "vLrAzsb6tPU=" && $IsMine eq 0){
		if( !$objUser->IsTargetUserAdult($strTargetName)){
			do_debug("Access denied - target is not adult");
			$objUser->Finalize();
			ReturnError(AccessDenied,$objUser->{strUserName} . "(ListDirectory3)=>" . $strDirectory);
		}	
		if ( $nAdult eq 0 ){
			do_debug("Access denied - not authenticate");
			$objUser->Finalize();
			ReturnError(RequestAuth,$objUser->{strUserName} . "(ListDirectory3)=>" . $strDirectory);
		}elsif( $nAdult eq 1 || $nAdult eq 3){
			do_debug("Access denied - user is not adult");
			$objUser->Finalize();
			ReturnError(AccessDenied,$objUser->{strUserName} . "(ListDirectory3)=>" . $strDirectory);
		}
	}
	my $objFileSystem = new eFolder::FileSystem;
	$nResult = $objFileSystem->ListDirectory3($strRealPath, $IsMine, $GroupCode, \@arrDirectoryList);

	$objUser->Finalize();
	if($nResult != SUCCESS) {
		do_debug("List directory fail Error");
		ReturnError($objFileSystem->GetError());
	}

	my $endTime =Time::HiRes::time();
	my $param = sprintf("%s ListDirectory3 RUN TIME: %.2fsec:[%s]",$objUser->{strUserName},$endTime - $startTime, $strDirectory);
	do_debug($param);

	do_debug("Success...");
	my $objSOAPHelper  = new eFolder::SOAPHelper;
	if($#arrDirectoryList != -1){
		return $objSOAPHelper->MakeDirListResponse3(\@arrDirectoryList);
	}else{
		ReturnError(EmptyData);
	}
}

sub GetFileAttribute{
	my ($class, $strTargetPath, @arrUser) = @_;

	do_debug("=======================");
	do_debug("execute...");

	do_debug("Parameter [targetpath : " . $strTargetPath . ", arrUser : " . join(",", @arrUser));

	my $objUser = new eFolder::UserObject;
	if($objUser->InitFromSession(@arrUser) !=SUCCESS){ 
		do_debug("Session not found Error");
		$objUser->Finalize();
		ReturnError(SessionNotFound);
	}
	my $nResult = $objUser->CheckUAS();
	if($nResult != SUCCESS){
		do_debug("User not found Error");
		$objUser->Finalize();
		ReturnError(AuthenticationFail);
	}

#	if( $objUser->HasRight($strTargetPath) eq 0){
#		$objUser->Finalize();
#      		ReturnError(PermissionDenied);
#   	}


	$strTargetPath = FixEncoding($strTargetPath);

	if ($strTargetPath eq "") {
		do_debug("Invalid character after FixEncoding");
		ReturnError(IconvFail, "at GetFileAttribute");
	}
	my $strRealPath = $objUser->GetRealPath($strTargetPath);
	
	my $objFileSystem = new eFolder::FileSystem;
	my $refHash = $objFileSystem->GetFileAttribute($strRealPath);
	$objUser->Finalize();
	
	do_debug("Success...");
	if(!defined($refHash)){
		ReturnError(EmptyData);
	}

	my $objSOAPHelper = new eFolder::SOAPHelper;
	return $objSOAPHelper->MakeFileAttributeResponse($refHash);
}

sub GetDriveInfo{
    	my($self, $strPath, @arrUser) = @_;
	
	do_debug("=======================");
	do_debug("execute...");

	do_debug("Parameter [path : " . $strPath . ", arrUser : " . join(",", @arrUser));
    
	my $objUser = new eFolder::UserObject;
	my ($refHash) = ();

    	if($objUser->InitFromSession(@arrUser) != SUCCESS) {
		do_debug("Session not found Error");
        	$objUser->Finalize();
        	ReturnError(SessionNotFound, $arrUser[0]);
    	}

    	if($objUser->CheckUAS() != SUCCESS){
		do_debug("User not found Error");
        	$objUser->Finalize();
        	ReturnError(AuthenticationFail, $arrUser[0]);
    	}

    	$strPath = FixEncoding($strPath);
    	if ($strPath eq "") {
		do_debug("Invalid character after FixEncoding");
        	ReturnError(IconvFail);
    	}
    
	my $strRealPath = $objUser->GetRealPath($strPath);
    	if(!defined($strRealPath)){
		do_debug("Invalid character after GetRealPath");
        	$objUser->Finalize();
        	ReturnError(EmptyData);
    	}

    	my $objFileSystem = new eFolder::FileSystem;
    	my $strVolumeName = $objUser->GetVolumeNameFromPath($strPath);

    	if( $objUser->HasRight($strPath) eq 0){
        	$refHash = $objFileSystem->UnAuthorizedVolume($strVolumeName);
    	}else{
        	$refHash = $objFileSystem->GetVolumeStats($strRealPath, $strVolumeName);
        	if(!defined($refHash)){
			do_debug("Cannot found volume stats");
            		$objUser->Finalize();
            		ReturnError(EmptyData);
        	}
    	}
    
	if($objUser->IsAdmin()){
                $refHash->{VolumeType} = 6;
        }

    	$objUser->Finalize();

    	my $objSOAPHelper = new eFolder::SOAPHelper;
    	return $objSOAPHelper->MakeGetDriveInfoResponse($refHash);
}

sub FindFiles2{
	my($self, $strWhat , $strPattern, $nStart, $bBlock, @arrUser) = @_;

	do_debug("=======================");
	do_debug("execute...");

	do_debug("Parameter [strWhat : " . $strWhat . ", strPattern : ". $strPattern . ", nStart : " . $nStart . ", bBlock : " . $bBlock . ", arrUser : " . join(",", @arrUser));
	
	my $objUser = new eFolder::UserObject;
	my @arrFileList = ();

	if($objUser->InitFromSession(@arrUser) != SUCCESS){
		do_debug("Session not found Error");
		$objUser->Finalize();
		ReturnError(SessionNotFound, $arrUser[0]);
	}

	if($objUser->CheckUAS() != SUCCESS) {
		do_debug("User not found Error");
		$objUser->Finalize();
		ReturnError(AuthenticationFail, $arrUser[0]);
	}
	my $bAdultAuth = $objUser->{bAdultAuth};
	
	$objUser->Finalize();

	$strWhat = FixEncoding($strWhat);
	$strPattern = FixEncoding($strPattern);
	
	$strPattern =~ s/\%//g; 
	$strPattern =~ s/_//g;
	$strPattern =~ s/\^embian\$/\%/g ;

	$nStart = FixEncoding($nStart);

	# 2005.06.28 LeeJaeSung
	my $strUTF8 = pack "U0C*", unpack "C*", $strPattern;	
	my $nLen = length($strUTF8);
	do_debug("strUTF8 : $strUTF8");
	if( $nLen < 2 ) {
		do_debug("Invalid character after FixEncoding");
		ReturnError(EmptyData);
	}
	# 2005.06.28 end

	$strPattern = FixEncoding($strPattern);
	my $objFileFinder = new eFolder::FileFinder;

	if( !$objUser->IsAdmin() ) {
		if($objFileFinder->IsVetoedWord($strPattern)){
			do_debug("Vetoed character '$strPattern'");
			ReturnError(VetoedWord, $strPattern);
		}
	}

	my $userName = $objUser->{strUserName};

	my @arrVolumeList;
	my $objFileSystem = new eFolder::FileSystem;
	my $strPath = $objUser->GetRealPath("Home:\\");
	#my $refHash = $objFileSystem->GetVolumeStats($strPath, "Home");
#	do_log("JAEJUNH", "$strPath, username=$userName");
	my $refHash = $objFileSystem->GetVolumeStats($strPath, $userName);
	$arrVolumeList[0] = $refHash;
	if(!defined($refHash)){
		do_debug("Home volume is not exist");
		$objUser->Finalize();
		ReturnError(EmptyData);
	}

	$objUser->GetMountList();

	my @arrAuthorizedShare = $objUser->GetAuthorizedShare();
	my @arrTeamShare = $objUser->GetTeamShare();
	
	my ($i, $j) = (0,1); 

	for( $i = 0 ; $i <= $#arrAuthorizedShare; $i ++){
			$strPath = $objUser->GetRealPath( $arrAuthorizedShare[$i].":\\");
			my $refHash = $objFileSystem->GetVolumeStats_Aux($strPath, $arrAuthorizedShare[$i]);
			if(defined($refHash)){
				$arrVolumeList[$j] = $refHash;
				$j ++;
			}
	}

	for($i = 0 ; $i <= $#arrTeamShare ; $i++ ){
		$strPath = $objUser->GetRealPath( $arrTeamShare[$i].":\\");
		my $refHash = $objFileSystem->GetVolumeStats_Aux($strPath, $arrTeamShare[$i]);
		if(defined($refHash)){
			$arrVolumeList[$j] = $refHash;
			$arrVolumeList[$j]->{VolumeType} = 11; # Team Type
			$j ++;
		}
	}

	my @arrVolumeNameList;
	for($i = 0 ; $i <= $#arrVolumeList ; $i++ ){
		push(@arrVolumeNameList, $arrVolumeList[$i]->{VolumeName});
	}

	my $strVolumeNameList = "('" . join("','", @arrVolumeNameList) . "')\n";

	if( $objFileFinder->FindFiles2($strWhat, $strPattern, $nStart, $bBlock, $strVolumeNameList, \@arrFileList) != SUCCESS){
		do_debug("FindFiles2 fail Error");
		ReturnError(EmptyData);
	}
	$objFileFinder->Finalize();

	do_debug("Success...");
	if($#arrFileList < 0)  {
		ReturnError(EmptyData);
	}else{
		 my $objSOAPHelper = new eFolder::SOAPHelper;
		 return $objSOAPHelper->MakeFindFilesResponse2(\@arrFileList);
	}
}

sub GetUserProfile2{
        my($class, @arrUser) = @_;

	do_debug("=======================");
	do_debug("execute...");

	do_debug("Parameter [arrUser : " . join(",", @arrUser));

        my $startTime =Time::HiRes::time();

        my $objUser = new eFolder::UserObject;
        if($objUser->InitFromSession(@arrUser) != SUCCESS){
		do_debug("Session not found Error");
                $objUser->Finalize();
                ReturnError(SessionNotFound, $arrUser[0]);
        }

        my $userName = $objUser->{strUserName};

        if($objUser->CheckUAS() != SUCCESS){
		do_debug("User not found Error");
                $objUser->Finalize();
                ReturnError(AuthenticationFail, $arrUser[0]);
        }

        my %objUserProfile2 = %{$objUser->GetUserProfile2()};
        $objUserProfile2{DownCharge} = eFolder_DOWN_CHARGE;
        $objUser->Finalize();
        my $objSOAPHelper = new eFolder::SOAPHelper;

        my $endTime =Time::HiRes::time();

        do_debug(sprintf("%s GetUserProfile2 time=%.2fsec",
                 $userName, $endTime - $startTime));

	do_debug("Success...");
        return $objSOAPHelper->MakeProfile2Response(\%objUserProfile2);
}

sub GetMountList{
	my($class, @arrUser) = @_;
	
	do_debug("=======================");
	do_debug("execute...");

	do_debug("Parameter [arrUser : " . join(",", @arrUser));

	my @arrVolumeList;

	my $startTime =Time::HiRes::time();
	my $objUser = new eFolder::UserObject;
	if($objUser->InitFromSession(@arrUser) != SUCCESS){
		do_debug("Session not found Error");
		$objUser->Finalize();
		ReturnError(SessionNotFound, $arrUser[0]);
	}

	my $userName = $objUser->{strUserName};

	if($objUser->CheckUAS() != SUCCESS){
		do_debug("User not found Error");
		$objUser->Finalize();
		ReturnError(AuthenticationFail, $arrUser[0]);
	}
	my $objFileSystem = new eFolder::FileSystem;
	my $strPath = $objUser->GetRealPath("Home:\\");
	#my $refHash = $objFileSystem->GetVolumeStats($strPath, "Home");
	my $refHash = $objFileSystem->GetVolumeStats($strPath, $userName);
	$arrVolumeList[0] = $refHash;
	if(!defined($refHash)){
		do_debug("Home volume is not exist");
		$objUser->Finalize();
		ReturnError(EmptyData);
	}

	$objUser->GetMountList();

	my @arrAuthorizedShare = $objUser->GetAuthorizedShare();
	my @arrUnAuthorizedShare = $objUser->GetUnAuthorizedShare();
	my @arrTeamShare = $objUser->GetTeamShare();
	
	my ($i, $j) = (0,1); 

	for($i = 0 ; $i <= $#arrUnAuthorizedShare; $i ++){
			$arrVolumeList[$j] = $objFileSystem->UnAuthorizedVolume($arrUnAuthorizedShare[$i]);
			if( $objUser->IsAdmin()){
                                $arrVolumeList[$j]->{VolumeType} = 6;
                        }
			$j ++;
	}

	for( $i = 0 ; $i <= $#arrAuthorizedShare; $i ++){
			$strPath = $objUser->GetRealPath( $arrAuthorizedShare[$i].":\\");
			my $refHash = $objFileSystem->GetVolumeStats_Aux($strPath, $arrAuthorizedShare[$i]);
			if(defined($refHash)){
				$arrVolumeList[$j] = $refHash;
				$j ++;
			}
	}

	for($i = 0 ; $i <= $#arrTeamShare ; $i++ ){
		$strPath = $objUser->GetRealPath( $arrTeamShare[$i].":\\");
		my $refHash = $objFileSystem->GetVolumeStats_Aux($strPath, $arrTeamShare[$i]);
		if(defined($refHash)){
			$arrVolumeList[$j] = $refHash;
			$arrVolumeList[$j]->{VolumeType} = 11; # Team Type
			$j ++;
		}
	}

	$objUser->Finalize();
	my $objSoapHelper = new eFolder::SOAPHelper;

	my $endTime =Time::HiRes::time();

        do_debug(sprintf("%s GetMountList time=%.2fsec",
                 $userName, $endTime - $startTime));

	do_debug("Success...");
#	print STDERR Dumper(@arrVolumeList);
	return $objSoapHelper->MakeVolumeListResponse(\@arrVolumeList);
}

sub Mount{
	my($class,$strDestination, @arrUser) = @_;
	
	do_debug("=======================");
	do_debug("execute...");

	do_debug("Parameter [strDestination : " . $strDestination . ", arrUser : " . join(",", @arrUser));

	my $objUser = new eFolder::UserObject;
	if($objUser->InitFromSession(@arrUser) != SUCCESS){
		do_debug("Session not found Error");
		$objUser->Finalize();
		ReturnError(SessionNotFound, $arrUser[0]);
	}
	if($objUser->CheckUAS() != SUCCESS){
		do_debug("User not found Error");
		$objUser->Finalize();
		ReturnError(AuthenticationFail, $arrUser[0]);
	}
	if($strDestination eq $objUser->GetUserName()){
		do_debug("Mount myself is always success");
		$objUser->Finalize();
		return 1;
	}
	
	my $nResult = $objUser->Mount($strDestination);
	if(!defined($nResult)){
		do_debug("Mount fail Error");
		$objUser->Finalize();
		ReturnError(UserProfileNotFound, $strDestination);
	}
	$objUser->Finalize();
	do_debug("Success...");
	return $nResult;
}

sub UnMount{
	my($class, $strDestination, @arrUser) = @_;
	do_debug("=======================");
	do_debug("execute...");

	do_debug("Parameter [strDestination : " . $strDestination . ", arrUser : " . join(",", @arrUser));

	my $objUser = new eFolder::UserObject;
	if($objUser->InitFromSession(@arrUser) != SUCCESS){
		do_debug("Session not found Error");
		$objUser->Finalize();
		ReturnError(SessionNotFound, $arrUser[0]);
	}

	if($objUser->CheckUAS() != SUCCESS){
		do_debug("User not found Error");
		$objUser->Finalize();
		ReturnError(AuthenticationFail, $arrUser[0]);
	}
	
	my $nResult = $objUser->UnMount($strDestination);
	if(!defined($nResult)){
		do_debug("Unmount fail Error");
		$objUser->Finalize();
		ReturnError(UserProfileNotFound,$strDestination);
	}
	$objUser->Finalize();
	
	do_debug("Success...");
	return $nResult;
}

sub SetShareOption{
	my($class, $nShareType, $strSharePassword, @arrUser) = @_;

	do_debug("=======================");
	do_debug("execute...");

	do_debug("Parameter [nShareType : " . $nShareType . ", strSharePassword : " . $strSharePassword . ", arrUser : " . join(",", @arrUser));
	
	my $objUser = new eFolder::UserObject;

	if($objUser->InitFromSession(@arrUser) != SUCCESS){
		do_debug("Session not found Error");
		$objUser->Finalize();
		ReturnError(SessionNotFound, $arrUser[0]);
	}

	if($objUser->CheckUAS() != SUCCESS){
		do_debug("User not found Error");
		$objUser->Finalize();
		ReturnError(AuthenticationFail, $arrUser[0]);
	}
	$nShareType = FixEncoding($nShareType);
	$strSharePassword = FixEncoding($strSharePassword);

        if ( $strSharePassword =~ /[^a-zA-Z0-9]/g) {
                do_debug("Invalid password character : $strSharePassword");
                ReturnError(AuthenticationFail, $arrUser[0]);
        }
	
	my $ret = $objUser->SetShareOption($nShareType, $strSharePassword);
	$objUser->Finalize();
	do_debug("Success...");
	return $ret;
}

sub Authorize{
	my ($class, $strVolumeName, $strSharePassword, @arrUser) = @_;
	
	do_debug("=======================");
	do_debug("execute...");

	do_debug("Parameter [strVolumeName : " . $strVolumeName . ", strSharePassword : " . $strSharePassword . ", arrUser : " . join(",", @arrUser));
	
	my $objUser = new eFolder::UserObject;

	if($objUser->InitFromSession(@arrUser) != SUCCESS){
		do_debug("Session not found Error");
		$objUser->Finalize();
		ReturnError(SessionNotFound, $arrUser[0]);
	}

	if($objUser->CheckUAS() != SUCCESS){
		do_debug("User not found Error");
		$objUser->Finalize();
		ReturnError(AuthenticationFail, $arrUser[0]);
	} 
   
	my $ret = $objUser->Authorize($strVolumeName, $strSharePassword) ;
	$objUser->Finalize();
	do_debug("Success...");
	return $ret;
}

sub main{
	#print MakeDirectory("FTPService", "/hjparkHome2", "hjpark", "hjpark");
	#print DeleteDirectory("FTPService", "/hjparkHome2", "hjpark", "hjpark");
	#print DeleteFile("FTPService", "/hjparkHome", "hjpark", "hjpark");
	#print Rename("FTPService", "/a.pl", "/b.pl", "hjpark", "hjpark");
#	print ListDirectory("FTPService", "/", "hjpark", "hjpark");
#	print  MakeShare("FTPService", "/한글.pl", 3, 100, "himan", "U068275696880");
#	print GetDriveInfo("FTPService", "embian://", "U5280186403355");
	#print FindFiles("FTPService", "name", "UAM", 100); 
	#GetMountList("FTPService", "U2750125969840");
	#my $sessionId = Authenticate("FTPService", "chunsj", "chunsj", 3.33);
#	my $res = SetAdultRegistry("pX2QrMkuj64qmY6sR7WWFQ","Ulfakjlkmwsdjflsjd");
#	my $res = MakeAppSessionID("goodjs:/2005-10-10.zip","goodjs","U67872920091709");
	#my $res = GetAppFileSize("G20051103090235");	
#	my $res = GetMountList("FTPService", "U8349202431852");	
#	print $res."\n";
#	print STDERR InnoDatabaseAddress . "\n";

}


#main;

1;
