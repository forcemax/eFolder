#!/usr/bin/perl

package eFolder::Session;

use strict;
use eFolder::CONFIG; 
use eFolder::CONSTANT;
use eFolder::Database;
use eFolder::UASHelper;

sub new {
	my($class) = @_;

	my $self={};
	   $self->{SessionDBConnection} = new eFolder::Database(SessionDatabaseAddress);
	   $self->{strError} = "";

	bless $self, $class;
}

sub AddUserSession{
	my($self, $strUserId, $strPassword) = @_;
	my ($nSessionId, $strSessionId) = (undef, undef);

	my $dbConn = $self->{SessionDBConnection};

	my $query = "SELECT SessionID FROM eFolder_UserSession WHERE UserId = '$strUserId'";
	do_debug($query);
	$dbConn->Sql($query);
	if($dbConn->IsError()){
		$self->{strError} = $dbConn->getErrMsg();
		return undef;
	}

	if(!$dbConn->FetchRow()){ 
		my ($foo,$bar,$nUID) = eFolder::UASHelper::getpwnam($strUserId);
		if (!$nUID) {
		        $self->{strError} = "getpwnam failed from AddUserSession!";
			return undef;
		}
		$query = "INSERT INTO eFolder_UserSession(SessionId, UserId, Password, HostAddress, TimeOut) values ($nUID, '$strUserId', '$strPassword', '$ENV{REMOTE_ADDR}', now())";
	#	$query = "INSERT INTO eFolder_UserSession(SessionId, UserId, Password, HostAddress, TimeOut, AdultAuth) values ($nUID, '$strUserId', '$strPassword', '$ENV{REMOTE_ADDR}', now(), '$nAdultAuth')";
                $nSessionId = $nUID;
	}else{
	 $nSessionId = $dbConn->Data("SessionID");
	 $query = "UPDATE eFolder_UserSession Set TimeOut = now(), HostAddress = '$ENV{REMOTE_ADDR}', Password = '$strPassword' WHERE UserId = '$strUserId' ";
	 #	$query = "UPDATE eFolder_UserSession Set TimeOut = now(), HostAddress = '$ENV{REMOTE_ADDR}', Password = '$strPassword' , AdultAuth = '$nAdultAuth' WHERE UserId = '$strUserId' ";
	} 
	do_debug($query);

	$dbConn->Sql($query);

	if($dbConn->IsError()){
		$self->{strError} = $dbConn->getErrMsg();
		return undef;
	}

#	if(!defined($nSessionId)){ 
#		$query = "SELECT LAST_INSERT_ID() as SessionId FROM eFolder_UserSession";
#		$dbConn->Sql($query);
#		if($dbConn->IsError()){
#			$self->{strError} = $dbConn->getErrMsg();
#			return undef;
#		}
#		$dbConn->FetchRow();
#		$nSessionId = $dbConn->Data("SessionId");
#	}
	$strSessionId = EncodeSessionId($nSessionId, "U");

	$query = "UPDATE eFolder_UserSession SET ClientName = '$strSessionId' WHERE UserId = '$strUserId'";

	$dbConn->Sql($query);

	if($dbConn->IsError()){
		$self->{strError} = $dbConn->getErrMsg();
		return undef;
	}

	return $strSessionId;
}

sub AddUserSession2{
	my($self, $strUserId, $strPassword, $nClientVersion, $nAdultAuth) = @_;
	my ($nSessionId, $strSessionId) = (undef, undef);
	do_debug("$strUserId, $strPassword, $nAdultAuth");

	my $dbConn = $self->{SessionDBConnection};
	
	my $query = "DELETE FROM eFolder_UserSession WHERE TimeOut < now() - interval 30 day";
	$dbConn->Sql($query);
	if($dbConn->IsError()){
		$self->{strError} = $dbConn->getErrMsg();
		return undef;
	}
	
	$query = "SELECT SessionID FROM eFolder_UserSession WHERE UserId = '$strUserId'";
	$dbConn->Sql($query);
	if($dbConn->IsError()){
		$self->{strError} = $dbConn->getErrMsg();
		return undef;
	}
	
	if(!$dbConn->FetchRow()){ 
		my ($foo,$bar,$nUID) = eFolder::UASHelper::getpwnam($strUserId);
		if (!$nUID) {
			$self->{strError} = "getpwnam failed from AddUserSession2!";
			return undef;
		}
		$nSessionId = $nUID;
		$strSessionId = EncodeSessionId($nSessionId, "U");
		$query = "INSERT INTO eFolder_UserSession(SessionId, UserId, Password, HostAddress, TimeOut, AdultAuth, ClientName) values ($nSessionId, '$strUserId', '$strPassword', '$ENV{REMOTE_ADDR}', now(), '$nAdultAuth', '$strSessionId')";
	}else{
		$nSessionId = $dbConn->Data("SessionID");
		$strSessionId = EncodeSessionId($nSessionId, "U");
	
		$query = "SELECT SessionID FROM eFolder_UserSession WHERE UserId = '$strUserId' AND ClientName = '$strSessionId'";
		$dbConn->Sql($query);
		if($dbConn->IsError()){
			$self->{strError} = $dbConn->getErrMsg();
			return undef;
		}

		if(!$dbConn->FetchRow()){
			$query = "INSERT INTO eFolder_UserSession(SessionId, UserId, Password, HostAddress, TimeOut, AdultAuth, ClientName) values ($nSessionId, '$strUserId', '$strPassword', '$ENV{REMOTE_ADDR}', now(), '$nAdultAuth', '$strSessionId')";
		} else {
			$query = "UPDATE eFolder_UserSession Set TimeOut = now(), HostAddress = '$ENV{REMOTE_ADDR}', Password = '$strPassword' , AdultAuth = '$nAdultAuth' WHERE UserId = '$strUserId' AND ClientName = '$strSessionId' ";
		}
	} 

	$dbConn->Sql($query);

	if($dbConn->IsError()){
		$self->{strError} = $dbConn->getErrMsg();
		return undef;
	}

	#$strSessionId = EncodeSessionId($nSessionId, "U");

	#$query = "UPDATE eFolder_UserSession SET ClientName = '$strSessionId' WHERE UserId = '$strUserId'";

	#$dbConn->Sql($query);

	#if($dbConn->IsError()){
	#	$self->{strError} = $dbConn->getErrMsg();
	#	return undef;
	#}

	return $strSessionId;
}

sub ChangeSessionPassword{
	my ($self, $strUserId, $strPassword) = @_;
	my $dbConn = new eFolder::Database(ShareDatabaseAddress);
	my $query = "UPDATE eFolder_UserSession SET Password = '$strPassword' WHERE UserId = '$strUserId'";
	$dbConn->Sql($query);
	if($dbConn->IsError()){
		$dbConn->Close();
		$self->{strError} = $dbConn->getErrMsg();
		return undef;
	}
	
	$query = "UPDATE eFolder_ShareSession SET Password = '$strPassword' WHERE UserId = '$strUserId'";
	$dbConn->Sql($query);
	if($dbConn->IsError()){
		$dbConn->Close();
		$self->{strError} = $dbConn->getErrMsg();
		return undef;
	}
	$dbConn->Close();
	return SUCCESS;
}

#return Plaintext userid, password to logon afs
sub GetUserCredential{
	my($self, $strSessionId, $strClientHost) = @_;
	my $dbConn = $self->{SessionDBConnection};

	my $nSessionId = DecodeSessionId($strSessionId);
#	my $query = "SELECT UserId, Password , HostAddress, Authorized, ClientName FROM eFolder_UserSession WHERE SessionId = $nSessionId";
	my $query = "SELECT UserID, Password , HostAddress, Authorized, ClientName, AdultAuth FROM eFolder_UserSession WHERE SessionId = $nSessionId AND ClientName = '$strSessionId'";
	$dbConn->Sql($query);
	if($dbConn->IsError()){
		$self->{strError} = $dbConn->getErrMsg();
		return undef;
	}

	if(!$dbConn->FetchRow()){
		return undef;
	}
	my $strUserName = $dbConn->Data("UserID");
	my $strPassword = $dbConn->Data("Password");
	my $strHostAddress = $dbConn->Data("HostAddress");
	my $strAuthorized = $dbConn->Data("Authorized");
	my $strOldSessionId = $dbConn->Data("ClientName");
	my $bAdultAuth = $dbConn->Data("AdultAuth");
#	my $bAdultAuth = 1;
	
	if (!($strOldSessionId eq $strSessionId)) {
		return undef;
	}

#	일단 사용자 데이터의 TimeOut 처리는 추후로 미룬다. 	
#	$query = "UPDATE eFolder_UserSession SET TimeOut = now() WHERE SessionId = $nSessionId";
#	$dbConn->Sql($query);
#	if($dbConn->IsError()){
#		$self->{strError} = $dbConn->getErrMsg();
#		return undef;
#	}

	#return ($strUserName, $strPassword, $strHostAddress, $strAuthorized);
	return ($strUserName, $strPassword, $strHostAddress, $strAuthorized, $bAdultAuth);

}

sub DeleteUserSession{
	my($self, $strSessionId) = @_;
	my $dbConn = $self->{SessionDBConnection};
	my $nSessionId = DecodeSessionId($strSessionId);
	my $query = "DELETE FROM eFolder_UserSession WHERE SessionId = $nSessionId AND ClientName = '$strSessionId'";
	print STDERR $query, "\n";
	$dbConn->Sql($query);
	if($dbConn->IsError()){
		$self->{strError} = $dbConn->getErrMsg();
		return undef;
	}
	return SUCCESS;
}

sub UpdateUserSessionInfo{
	my($self, $strWhat, $strTo , $strSessionId) = @_;
	my $dbConn = $self->{SessionDBConnection} ;
	$strTo = $dbConn->Quote($strTo);
	my $nSessionId = DecodeSessionId($strSessionId);
	my $query = "UPDATE eFolder_UserSession SET $strWhat = $strTo WHERE SessionId = $nSessionId AND ClientName = '$strSessionId'";
	unless( $dbConn->Sql($query)){
		return 0;
	}
	return 1;
}

sub ViewUserSessions{
	my($self) = @_;
	my $dbConn = $self->{SessionDBConnection} ;
	my $query = "SELECT SessionId, UserId, Password, TimeOut FROM eFolder_UserSession";
	$dbConn->Sql($query);
	if($dbConn->IsError()){
		$self->{strError} = $dbConn->getErrMsg();
		return undef;
	}

	while($dbConn->FetchRow()){
		my ($lSessionId, $strUserId, $strPassword, $lTimeOut) = ();
		$lSessionId = $dbConn->Data("SessionId");
		$strUserId = $dbConn->Data("UserId");
		$strPassword = $dbConn->Data("Password");
		$lTimeOut = $dbConn->Data("TimeOut");

		print  " $lSessionId : $strUserId : $strPassword : $lTimeOut \n";
	}

	return SUCCESS;
}

sub SaveShareAuthInfo{
	my($self, $strAuthList, $strSessionId) = @_;
	my $dbConn = $self->{SessionDBConnection} ;
  	my $nSessionId = DecodeSessionId($strSessionId);

	my $query = "UPDATE eFolder_UserSession SET Authorized = '$strAuthList' 
					 WHERE SessionId = $nSessionId ";
	$dbConn->Sql($query);
	if($dbConn->IsError()){
		$self->{strError} = $dbConn->getErrMsg();
		return undef;
	}
	return 1;
}


sub Finalize{
	my($self) = @_;
	my $dbConn = $self->{SessionDBConnection};
	$dbConn->Close();
}

sub EncodeSessionId{
	my($nSessionId, $bSessionType) = @_;
	srand(time()^($$ + ($$<<15)));
	my $nRandom1 = ((rand) * 100000) % 10000;
	my $nRandom2 = ((rand) * 100000) % 10000;
	my $nEncoded = $nRandom1 + $nRandom2 + $nSessionId;

	return $bSessionType . sprintf("%04d%d%04d", $nRandom1, $nEncoded, $nRandom2);
}

sub DecodeSessionId{
	my($strSessionId) = @_;
	my $nSessionId  = substr($strSessionId, 1, length($strSessionId) -1); 

	my $nLength = length($nSessionId);
	my $nRandom1 = substr($nSessionId, 0, 4);
	my $nRandom2 = substr($nSessionId, $nLength - 4 , 4);
	my $Encoded = substr($nSessionId, 4, $nLength - 8);
	return int($Encoded) - int($nRandom1) - int($nRandom2);
}


1;
