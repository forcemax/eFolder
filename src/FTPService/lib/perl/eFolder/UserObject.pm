#!/usr/bin/perl 

package eFolder::UserObject;

use strict;
use eFolder::CONSTANT;
use eFolder::Session;
use SOAP::Lite;
use eFolder::CONFIG;
use eFolder::UASHelper;
use eFolder::Account;

# 1=> Session Not Found Error 
# 2=> Authentication Fail
# 0=> NoError

sub new {
	my($class) = @_;
	my $self = ();

	$self->{strSessionId} = "";
	$self->{strUserName}  = "";
	$self->{strUserPassword} = "";
	$self->{strRealName} = "";

	$self->{strAuthorizedShare} = "";
	$self->{strUnAuthorizedShare} = "";
	$self->{strTeamShare} = "";

	$self->{nErrorCode} = NO_ERROR;
	$self->{GroupCode} = "";
	$self->{objSession} = undef;
	bless $self, $class;
}

sub IsAdmin{
        my($self) = @_;
	
	# for only SuperClient Server Configuration
	# "THIS_SERVER_IS_SUPERC = 1" => This server is SuperClient Server
	if( THIS_SERVER_IS_SUPERC eq 0 ){
		return 0;
	}

	my %admin_id = ();
        my %admin_ip = ();

        my @arr_admin = split(/\|/, S_ADMIN);
        foreach my $id (@arr_admin) {
                $id =~ s/ //g;
                $admin_id{$id} = 1;
        }

        my @arr_admin_ip = split(/\|/, S_ADMIN_IP);
        foreach my $ip (@arr_admin_ip) {
                $ip =~ s/ //g;
                $admin_ip{$ip} = 1;
        }

        my $remote_ip = $ENV{REMOTE_ADDR};

        if($admin_id{$self->{strUserName}}){
		print STDERR "Super User Name Correct!! [$self->{strUserName}]". "\n";
                if( $admin_ip{$remote_ip} ){
                        print STDERR "[SUPER_SERVER] REMOTE IP :".$ENV{REMOTE_ADDR}."\n";
                        return 1;
                }
        }

        return 0;

}

sub Init{
	my($self, @arrUser) = @_;
	$self->{strUserName} =  $arrUser[0];
	$self->{strUserPassword} = $arrUser[1];
 	
	if( $self->IsAdmin() ) {
        	if($arrUser[2] ne SuperClientVersion){
        	        return ERROR;
	        }

	}else{
		do_debug(join(", ", "user=$arrUser[0]", "pass=$arrUser[1]", "version=$arrUser[2]"));
		if($arrUser[2] < ClientVersion){
			return ERROR;
		}
	}

	return SUCCESS;
}


sub InitFromSession{
	my($self, @arrUser) = @_;

	do_debug("execute...");

	my @arrCredential = ();
	my ($package, $filename, $line) = caller;
	my $objSession = new eFolder::Session;
	my $isShare = 0;

	
	$self->{strSessionId} = $arrUser[0];

	#print STDERR "UserObject : SessionId = $self->{strSessionId} \n";
	

	if($arrUser[0] =~ /U[0-9]+/){
		@arrCredential = $objSession->GetUserCredential($arrUser[0]);
	}else{
		do_debug("Unknown session format : $arrUser[0]");
		$self->{nErrorCode} = 1;
		$objSession->Finalize();
		return ERROR;
	}

	$objSession->Finalize();
	if(!defined($arrCredential[0])){
		do_debug("Cannot found session data");
		$self->{nErrorCode} = 1; 
		return ERROR;
	}

#	if( $isShare != 2 && $isShare != 1 && $ENV{REMOTE_ADDR} ne $arrCredential[2]){
#		do_debug("remote address does not match: ", $ENV{REMOTE_ADDR}, ": ", $arrCredential[2]);
#	}
		

	$self->{strUserName} = $arrCredential[0];
	$self->{strUserPassword} = $arrCredential[1];
	$self->{strAuthorizedShare} =  $arrCredential[3];
	$self->{bAdultAuth} =  $arrCredential[4];
#	$self->{bAdultAuth} =  1;
	
	$self->{nErrorCode} = 0; 
	$self->{objSession} = $objSession;
	do_debug("Success...");
	return SUCCESS;
}

sub GetShareFilePath{
	my($self) = @_;
	return $self->{strShareFilePath};
}

sub GetRealName{
	my($self) = @_;
	my @arrUserProfile = eFolder::UASHelper::getpwnam($self->{strUserName});
	$self->{strRealName} = $arrUserProfile[6];
	return $self->{strRealName} ;
}

sub CheckFireDate{
	my($self) = @_;
	
	my $objSession = new eFolder::Session;
	if(!$objSession->CheckFireDate($self->{strSessionId})){
		return undef;
	}	
	$objSession->Finalize();
	
	return SUCCESS;
}

sub ComputePlainPassword{
	my($self) = @_;
}

sub GetUserName{
	my($self) = @_;
	return $self->{strUserName};
}


sub GetUserPlainPassword{
	my($self) = @_;
	return $self->{strUserPassword}; 
}

sub GetErrorCode{
	my ($self) = @_;
	return $self->{ErrorCode} ;
}


sub CheckUAS {
	my ($self, $userid) = @_;

	do_debug("execute...");

	do_debug("Parameter [userid : " . $userid);
	
	my @item = ();
	if( defined($userid) ){ 
	        @item = eFolder::UASHelper::getpwnam($userid);
	}elsif(defined($self->{strUserName}) ){
		@item = eFolder::UASHelper::getpwnam($self->{strUserName});
	}else {
		@item = eFolder::UASHelper::getpwnam(UAS_TEST_USER);
	}

	do_debug(join(",", @item));
        if( !defined(@item) ){
                return ERROR;
        }

	if( defined($userid) ){ 
	        my $point = 1;

        	$self->{GroupCode} = sprintf("A%03d",$point);
	}

	do_debug("Success...");
        return SUCCESS;
}

sub CheckAdultAuthenticate{
	my ($self, $strUserID) = @_;
	my $dbConn = new eFolder::Database(WebDatabaseAddress);
	$strUserID = $dbConn->Quote($strUserID);
	my $query = "SELECT adult FROM member WHERE id = $strUserID";
	$dbConn->Sql($query);

        if ($dbConn->IsError()) {
                $dbConn->Close();
                return ERROR;
        }
	
	if(!$dbConn->FetchRow()){
		$dbConn->Close();
		return undef;
	}

	my $nAdultAuth =  $dbConn->Data("adult");
	$dbConn->Close();
	
	return $nAdultAuth;
	
}

sub Authenticate {
	my ($self) = @_;

	my $dbConn = new eFolder::Database(UASDatabaseAddress);
	my $userName = $self->{strUserName};
	my $password = $self->{strUserPassword};
	my $query = "SELECT NAME_COL FROM ACT_TBL WHERE NAME_COL='$userName' and PLPWD_COL='$password' and ENPWD_COL != '!!' and PLPWD_COL != ''";

	$dbConn->Sql($query);

	if ($dbConn->IsError()) {
		$dbConn->Close();
		return ERROR;
	}

	my $loginOK = "";
	if ($dbConn->FetchRow()) {
		$loginOK = $dbConn->Data("NAME_COL");
	}
	$dbConn->Close();

	if ($loginOK ne $userName) {
		return ERROR;
	}
	$self->{nErrorCode} = 0;

	if ( THIS_SERVER_IS_SUPERC eq 1 ){
                return $self->IsAdmin() ;
        }

	return SUCCESS;
}


sub ChangePassword{
	my($self, $strNewPassword) = @_;
	$self->{nErrorCode} = 2;
	if(!defined($strNewPassword)) {
		return ERROR;
	}

	my $strNewEnPassword = crypt($strNewPassword, "eFolder"); 
	my $UASDB = new eFolder::Database(UASDatabaseAddress);
	my $strUserName = $UASDB->Quote($self->{strUserName});
	my $strQNewPassword = $UASDB->Quote($strNewPassword);
	$strNewEnPassword = $UASDB->Quote($strNewEnPassword);
	my $query = "UPDATE ACT_TBL SET PLPWD_COL = $strQNewPassword, ENPWD_COL = $strNewEnPassword WHERE NAME_COL = $strUserName";
	unless ( $UASDB->Sql($query) ) {
		$UASDB->Close();
		return ERROR;
	}
	$UASDB->Close();

	my $objSession = new eFolder::Session;
	if($objSession->ChangeSessionPassword($self->{strUserName}, $strNewPassword) != SUCCESS) {
		$self->{ErrorCode} = $objSession->GetErrorCode();
		$objSession->Finalize();
		return ERROR;
	}
	$objSession->Finalize();
	return SUCCESS;
}


sub GetRealPath{
	my($self, $strPath) = @_;
	my ($strUserName, $strUserPath, $homeDir) = ();

	$strPath =~ s/\\/\//g;
	if($strPath =~ /(.*):\/(.*)/){
		$strUserName  = $1;
		$strUserPath  = $2;
	}

	if($strUserName eq "Home"){
		$strUserName = $self->{strUserName};
	}
	my @arrUserProfile = eFolder::UASHelper::getpwnam($strUserName);
	if(!defined(@arrUserProfile)){
		return undef;
	}
	$homeDir = $arrUserProfile[7];
	if(!defined($homeDir)){
		do_debug("Undefined home directory");
		return undef;
	}
	return $homeDir ."/". $strUserPath;
}

sub GetVolumeNameFromPath{
	my($self, $strPath) = @_;
	my $strUserName;

    $strPath =~ s/\\/\//g;
    if($strPath =~ /^([^\:]+)\:\/(.*)/){
        $strUserName  = $1;
    }

    if($strUserName eq "Home"){
        return $self->{strUserName};
    }else{
		return $strUserName;
	}
}

sub GetVolumePathFromPath{
    my($self, $strPath) = @_;
    my $strUserPath;

        $strPath =~ s/\\/\//g;
        if($strPath =~ /^([^\:]+)\:\/(.*)/){
                $strUserPath  = $2;
        }

	if ($strUserPath !~ /^\//) {
		$strUserPath = "/" . $strUserPath;
	}
        return $strUserPath;
}

 
sub Finalize{
	my($self) = @_;
}

sub GetUserProfile2 {
        my ($self) = @_;
        my %objUserProfile;
	my $hAccount = new eFolder::Account;
	($objUserProfile{Coin},
		$objUserProfile{ExpireDate},
		$objUserProfile{ShareType},
		$objUserProfile{TodayCharge},
		$objUserProfile{Mileage}) = $hAccount->GetUserProfile2($self->{strUserName});
	$hAccount->Finalize();
        return \%objUserProfile;
}


sub GetTodayCharge{
	my ($self) = @_;
        my $hAccountDB =  new eFolder::Account;
        my $ret = $hAccountDB->GetTodayCharge($self->{strUserName});
        $hAccountDB->Finalize();
        return $ret;
}



sub GetUserType{
	my($self) = @_;
	my @arrUserProfile = eFolder::UASHelper::getpwnam($self->{strUserName});
	my $homeDir = $arrUserProfile[7];
	if(!defined($homeDir)){
		return undef;
	}
	
	if( $homeDir =~  /\/Public[0-9]*\//){
		return "PUBLIC";
	}else{
		return "NORMAL";
	}
}


sub GetShareType{
	my($self) = @_;
	my $hAccount = new eFolder::Account;
	my $ret = $hAccount->GetShareType($self->{strUserName});
	$hAccount->Finalize();
	return $ret;
}

sub GetMileage{
	my($self) = @_;
	my $hAccount = new eFolder::Account;
	my $ret = $hAccount->GetCoin($self->{strUserName});
	$hAccount->Finalize();
	return $ret;
}

sub IsTargetUserAdult{
	my ($self, $strUserName) = @_;
	my $hAccount = new eFolder::Account("NOT_USE_DB");
	my $Adult = $hAccount->GetUserAdult($strUserName);
	$hAccount->Finalize();
	if( $Adult eq 0 || $Adult eq 1 || $Adult eq 3){
		return 0;
	}elsif( $Adult eq 2 || $Adult eq 4){
		return 1;
	}else{
		return 0;
	}
}

sub GetExpireDate{
	my($self) = @_;
	return "2099-12-31";
}


sub Authorize{
	my ($self, $strVolumeName, $strSharePassword) = @_;
	my $hAccount = new eFolder::Account;
	my $ret = $hAccount->Authorize($strVolumeName, $strSharePassword);

	if($ret eq 1) {
		$hAccount->UpdateMountPassword($self->{strUserName}, $strVolumeName, $strSharePassword);
		my $hSession = new eFolder::Session;
		my $strAuthorizedShare = $self->{strAuthorizedShare};
                my %hashAuthorized = ();
                foreach my $i (split(/\,/, $strAuthorizedShare)) {
                        $hashAuthorized{$i} = 1;
                }
                $hashAuthorized{$strVolumeName} = 1;
                $strAuthorizedShare = join(",", keys %hashAuthorized);

                if (length($strAuthorizedShare) > 253) {
                        $hSession->Finalize();
                        $hAccount->Finalize();
                        return 0;
                }

		$hSession->UpdateUserSessionInfo("Authorized", $strAuthorizedShare, $self->{strSessionId});
		$hSession->Finalize();
	}
	$hAccount->Finalize();
	return $ret;
}


sub GetMountList {
        my ($self) = @_;

        my $i ;
        my (@arrAuthorizedShare, @arrUnAuthorizedShare, @arrTeamShare) = ();

        my $hAccount = new eFolder::Account;
        $hAccount->GetMountListAndAuthorize($self->{strUserName}, \@arrAuthorizedShare, \@arrUnAuthorizedShare);

	$hAccount->GetTeamMountList($self->{strUserName}, \@arrTeamShare);

        $self->{strAuthorizedShare} = join(",", @arrAuthorizedShare);
	# 2011.3.8.  jaejunh:  arrAuthorizedShare must have his/her account
        #$self->{strAuthorizedShare} = join(",", @arrAuthorizedShare, $self->{strUserName});
        $self->{strUnAuthorizedShare} = join(",", @arrUnAuthorizedShare);
        $self->{strTeamShare} = join(",", @arrTeamShare);
	
       	my $hSession = new eFolder::Session;
       	$hSession->SaveShareAuthInfo($self->{strAuthorizedShare} , $self->{strSessionId});
       	$hSession->Finalize();

        $hAccount->Finalize();

        return 1;
}

sub GetAuthorizedShare{
	my ($self) = @_;
	return split(/,/, $self->{strAuthorizedShare});
}

sub GetUnAuthorizedShare{
	my ($self) = @_;
	return split(/,/, $self->{strUnAuthorizedShare});
}

sub GetTeamShare{
	my ($self) = @_;
	return split(/,/, $self->{strTeamShare});
}

sub Mount{
	my ($self, $strDestination) = @_;
	if( $self->IsGroup($strDestination) ){
		return 0;
	}

	my $hAccount = new eFolder::Account;
	my $ret = $hAccount->AddMemberToMount($self->{strUserName}, $strDestination);
	$hAccount->Finalize();
	if($ret eq 0) { return 0;	}

	$self->Authorize($strDestination, "");

	return $ret;
}

sub UnMount{
	my($self, $strDestination) = @_;
	my $hAccount = new eFolder::Account;
	my $ret = $hAccount->DeleteMemberFromMount($self->{strUserName}, $strDestination);
	$hAccount->Finalize();
	return $ret;
}

sub IsGroup {
	my ($self, $volName) = @_;

	my $AccountDB =	new eFolder::Database(AccountDatabaseAddress);

	if ( !$AccountDB ) {
		do_debug("Cannot Connect AccountDB, at Check Group");
		return 0;
	}

	$volName = $AccountDB->Quote($volName);
	my $query = " SELECT idx_col FROM team_tbl WHERE teamid_col = $volName ";
	unless($AccountDB->Sql($query)) {return 0;}
	unless($AccountDB->FetchRow()) {return 0;}
	my $idx = $AccountDB->Data("idx");
	$AccountDB->Close();
	do_debug("$volName is Group");
	return 1;
}

sub IsOwner {
        my ($self, $strShareName) = @_;
	do_debug("IsOwner: $strShareName");
	if( $self->IsAdmin() ) {
                do_debug("[SUPER_SERVER] IsOwner SuperUser!!");
                return 1;
        }

        my $strVolumeName = $self->GetVolumeNameFromPath($strShareName);
	if ($strShareName =~ /[\/\\]\.\.[\/\\]/) { return 0; }
	if ($strVolumeName eq $self->{strUserName}) { return 1; }
	do_debug("IsOwner-VolumeName !!!: $strVolumeName");
	if ($self->IsGroup($strVolumeName) ) { return 1; }
	do_debug("Group check pass");
        return 0;
}


sub HasRight{
	my ($self, $strShareName) = @_;
	if( $self->IsAdmin() ) {
                do_debug("[SUPER_SERVER] HasRight SuperUser!!");
                return 1;
	}

	my $strVolumeName = $self->GetVolumeNameFromPath($strShareName);

	if ($self->IsGroup($strVolumeName) ) { return 1; }

	if($strVolumeName eq $self->{strUserName}) { return 1; }

	my @arrAuthorizedShare = split(/,/, $self->{strAuthorizedShare}); 
	my $i  = 0;
	for($i = 0; $i <= $#arrAuthorizedShare ; $i ++){
		if($strVolumeName eq $arrAuthorizedShare[$i] ){
			return 1;
		}
	}
	return 0;
}

sub SetShareOption{
	my($self, $nShareType, $strSharePassword) = @_;
	my $hAccount = new eFolder::Account;
	if($hAccount->SetShareOption($self->{strUserName}, $nShareType, $strSharePassword) eq 0 ){
		do_debug("SetShareOption call fail");
		return 0;
	}
	$hAccount->Finalize();
	return 1;
}


sub main{
#	my $userobj = new eFolder::UserObject;
#	$userobj->{strUserName} = "goodjs";
#	my $strPath = $userobj->GetRealPath("goodjs:\\");
#	print "RealPath is" .$strPath,"\n";
#	my $IsDown = $userobj->HasEnoughMoney_Local("100000000");
#	if($IsDown == 1 ){
#		print "DOWN ENABLE\n";
#	}else{
#		print "DOWN DISABLE\n";
#	}
}

#main();

1;
