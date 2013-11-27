#!/usr/bin/perl
package eFolder::Account;
use strict;
use eFolder::CONFIG; 
use eFolder::CONSTANT;
use eFolder::Database;
use eFolder::UserObject;
use eFolder::UASHelper;  # getpwnam override
use POSIX qw(strftime);


sub new {
	my($class, $USEDB) = @_;
	my $self=();
	if ( !defined($USEDB) ){
	   $self->{AccountDBConnection} = new eFolder::Database(AccountDatabaseAddress);
	}
	
        $self->{strError} = "";
	
	bless $self, $class;
}

sub GetUserAdult{
	my($self, $strUserName) = @_;
	my $Webdb = new eFolder::Database(WebDatabaseAddress);
	$strUserName = $Webdb->Quote($strUserName);
   	my $query = " SELECT adult FROM member WHERE id = $strUserName ";
   	unless($Webdb->Sql($query)){  return undef; }
   	unless($Webdb->FetchRow()){   return undef; }
   	my $Adult = $Webdb->Data("adult");
   	$Webdb->Close();
   	return $Adult;

}

sub GetShareType{
	my($self,$strUserName) = @_;
	my $db = $self->{AccountDBConnection};
	$strUserName = $db->Quote($strUserName);
	my $query = " SELECT sharetype_col FROM account_tbl WHERE username_col = $strUserName";
	unless($db->Sql($query)) 	{ 	return undef;	}
	unless($db->FetchRow())		{	return undef;	}
	my $nShareType = $db->Data("sharetype_col");
	return $nShareType;
}


sub GetUserProfile2 {
   my($self,$strUserName) = @_;
   my ($nCoin, $strExpireDate, $nShareType, $nTodayCharge, $nPoint) = 
		( undef,"2099-12-31",undef,undef,undef); 

   my $db = $self->{AccountDBConnection};
   my $Webdb = new eFolder::Database(WebDatabaseAddress);
   $strUserName = $db->Quote($strUserName);

   my $query = " SELECT sharetype_col FROM account_tbl WHERE username_col = $strUserName";
   if ($db->Sql($query) && $db->FetchRow()) {
   	$nShareType = $db->Data("sharetype_col");
   }

   $query = " SELECT coin, mileage, charge_size FROM member WHERE id = $strUserName ";
   if ($Webdb->Sql($query) && $Webdb->FetchRow())  { 
   	$nCoin = int($Webdb->Data("coin"));
   	$nPoint = int($Webdb->Data("mileage"));
	$nTodayCharge = int($Webdb->Data("charge_size")/eFolder_DAY_CHARGE);
   }
   $Webdb->Close();
   return ($nCoin, $strExpireDate, $nShareType, $nTodayCharge, $nPoint); 
}

	

sub GetMemberCount {
    my ($self, $strUserName) = @_;
    my %passwd1 = ();
    my $db = $self->{AccountDBConnection};
    my @delete_list = ();
    my $quoted_username = $db->Quote($strUserName);
    my $query = " select m.member_col as member_col, m.sharepassword_col as password1 from mount_tbl m where m.owner_col=$quoted_username";
#    print STDERR $query, "\n";

    unless ($db->Sql($query)) {
        return 0;
    }

    while ($db->FetchRow()) {
	
	my ($id,$bar) = eFolder::UASHelper::getpwnam($db->Data("member_col"));
	if ($id) {
        	$passwd1{$db->Data("member_col")} = $db->Data("password1");
	} else {
		push(@delete_list,$db->Quote($db->Data("member_col")));
	}
    }

   if ($#delete_list >= 0) {
   	$db->Sql("delete from mount_tbl where owner_col = $quoted_username and member_col in (" . join(",", @delete_list) . ")");
   #print STDERR sprintf("delete from mount_tbl where owner_col = $quoted_username and member_col in (" . join(",", @delete_list) . ")"), "\n";
   
   }
   

    my $where_clause = "(";
    my $i;
    foreach $i (keys %passwd1) {
        $where_clause .= $db->Quote($i) . ",";
    }
    $where_clause .= "'jaejunh_rules!')";
    

    $query = " select count(*) as num from account_tbl a where a.username_col in $where_clause";

#    print STDERR $query, "\n";

    unless ($db->Sql($query)) {
        return 0;
    }

    my $num = 0;
    while ($db->FetchRow()) {
        $num  =  $db->Data("num");
    }
    return $num;
}
sub GetTeamMountList {
	my ($self, $strUserName, $arrTeamShare) = @_;
	my $db = $self->{AccountDBConnection};

	my $quoted_username = $db->Quote($strUserName);
	my $query = "select teamid_col from teammount_tbl where userid_col=$quoted_username";
#    print STDERR $query, "\n";

    	unless ($db->Sql($query)) {
        	return undef;
    	}

    	while ($db->FetchRow()) {
		push(@$arrTeamShare, $db->Data("teamid_col"));
    	}
}

sub GetMountListAndAuthorize{
    	my ($self, $strUserName, $arrAuthorizedShare, $arrUnAuthorizedShare) = @_;
    	my %passwd1 = ();
    	my $db = $self->{AccountDBConnection};


    	my $quoted_username = $db->Quote($strUserName);
#	my $query = " select a.username_col as username_col, m.sharepassword_col as password1, a.sharetype_col as sharetype_col, a.sharepassword_col as password2 from mount_tbl m,account_tbl a where m.member_col=a.username_col and m.owner_col= $quoted_username";
    	my $query = " select m.member_col as member_col, m.sharepassword_col as password1 from mount_tbl m where m.owner_col=$quoted_username";
#    print STDERR $query, "\n";

    	unless ($db->Sql($query)) {
        	return undef;
    	}

    	while ($db->FetchRow()) {
    		$passwd1{$db->Data("member_col")} = $db->Data("password1");
    	}

    	my $where_clause = "(";
    	my $i;
    	foreach $i (keys %passwd1) {
		$where_clause .= $db->Quote($i) . ",";
    	}
    	$where_clause .= "'embian_rules!')";

    	$query = " select a.username_col as username_col, a.sharetype_col as sharetype_col, a.sharepassword_col as password2 from account_tbl a where a.username_col in $where_clause";
 
    	unless ($db->Sql($query)) {
        	return undef;
    	}

    	while ($db->FetchRow()) {
    		my $nShareType  =  $db->Data("sharetype_col");
		my $strShare = $db->Data("username_col");
    		my $strSharePassword1 = $passwd1{$strShare};
    		my $strSharePassword2 = $db->Data("password2");
	
		if ($nShareType eq 2) {
			push(@$arrUnAuthorizedShare, $strShare);
		} elsif ($nShareType eq 1) { 
			push(@$arrAuthorizedShare, $strShare);
		} elsif ($strSharePassword1 eq $strSharePassword2) {
			push(@$arrAuthorizedShare, $strShare);
		} else {
			push(@$arrUnAuthorizedShare, $strShare);
		}
    	}

    	return 1;
}

sub GetMountList{
	my ($self, $strUserName) = @_;
    my $db = $self->{AccountDBConnection};

    my $quoted_username = $db->Quote($strUserName);
    my $query = "SELECT member_col, sharepassword_col "
                . "FROM mount_tbl "
                . "WHERE owner_col = $quoted_username";
    unless ($db->Sql($query)) {
        return undef;
    }

    my %arrMember;
    while ($db->FetchRow()) {
        $arrMember{$db->Data("member_col")} = $db->Data("sharepassword_col");
    }

    return \%arrMember;
}

sub Authorize{
	my ($self, $strUser, $strPassword) = @_;
	my $db = $self->{AccountDBConnection};
	my $quoted_username = $db->Quote($strUser) ;
	my $query = "SELECT sharetype_col, sharepassword_col "
					. 	"FROM  account_tbl "
					. 	"WHERE username_col = $quoted_username ";
	
	unless($db->Sql($query)){
		return undef;
	}

	if(!$db->FetchRow()){
		return undef;
	}

	my $nShareType  =  $db->Data("sharetype_col");
	my $strSharePassword = $db->Data("sharepassword_col");

	if($nShareType eq 1){ return 1; }
	if($nShareType eq 2){ return -1; }
	if( $strSharePassword eq $strPassword) { return 1; }
	return 0;
}

sub UpdateMountPassword{
	my ($self, $strUser, $strVolumeName, $strPassword) = @_;
	my $db = $self->{AccountDBConnection};
	$strUser = $db->Quote($strUser);
	$strVolumeName = $db->Quote($strVolumeName);
	$strPassword = $db->Quote($strPassword);
	my $query = " UPDATE mount_tbl SET sharepassword_col = $strPassword "
					. "WHERE owner_col = $strUser and  member_col = $strVolumeName";
	
	unless($db->Sql($query)){
		return 0;
	}
	return 1;
}


sub AddMemberToMount {
    my ($self, $username, $member) = @_;
    my $db = $self->{AccountDBConnection};
    my $quoted_username = $db->Quote($username);
    my $quoted_member = $db->Quote($member);

    # UAS 에서 실제 친구 추가하려는 사용자가 존재하는지 검사
    my @AddOK = eFolder::UASHelper::getpwnam($member); 
    
    if( defined(@AddOK) ){
    	my $mountcount = $self->GetMemberCount($username);
	
   	 if ($mountcount >= CMountMAX) {
   	     return undef;
   	 }

     	 my $query = "INSERT INTO mount_tbl "
      	          . "(owner_col, member_col) VALUES ("
        	  . "$quoted_username, $quoted_member)";

         unless ($db->Sql($query)) {
             return undef;
    	 }
   
    }else{
	return undef;
    }

    return 1;
}

sub DeleteMemberFromMount {
    my ($self, $username, $member)  = @_;

    my $db = $self->{AccountDBConnection};
    my $quoted_username = $db->Quote($username);
    my $quoted_member = $db->Quote($member);

    my $query = 	"DELETE FROM mount_tbl "
                . "WHERE owner_col = $quoted_username "
                . "AND member_col = $quoted_member";

    unless ($db->Sql($query)) {
        return undef;
    }

    return 1;
}

sub SetShareOption{
	my ($self, $strUserName, $nShareType, $strSharePassword) = @_;
	my $db = $self->{AccountDBConnection};
	my $quoted_password = $db->Quote($strSharePassword);
	my $quoted_name = $db->Quote($strUserName);
	
	my $query =  "UPDATE account_tbl SET sharetype_col = $nShareType , sharepassword_col = $quoted_password "
					. "WHERE username_col = $quoted_name ";

	unless($db->Sql($query)){
		return 0;
	}

	return 1;
}

sub SetStorageType{
        my ($self, $strUserName, $nStorageType) = @_;
        my $db = new eFolder::Database(WebDatabaseAddress);
        my $quoted_name = $db->Quote($strUserName);
        my $query =  "UPDATE member SET storage = $nStorageType "
                                        . "WHERE id = $quoted_name ";


        unless($db->Sql($query)){
		$db->Close();
                return 0;
        }
	$db->Close();

        return 1;
}

sub Finalize{
	my ($self) = @_;
	my $db = $self->{AccountDBConnection};
	if( defined($db)){
		$db->Close();
	}
}	
	
1;
