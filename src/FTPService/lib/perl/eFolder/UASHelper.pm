#!/usr/bin/perl 

package eFolder::UASHelper;

use strict;
use eFolder::CONSTANT;
use eFolder::CONFIG;
use eFolder::Database;
use eFolder::UASHelper;

#if ($^O =~ /linux/i) { eval 'use POSIX qw(getpwnam);'; } else { eval 'sub getpwnam; *getpwnam = \&getpwnam_helper;'; }


# 1=> Session Not Found Error 
# 2=> Authentication Fail
# 0=> NoError

# ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire) = getpw*

sub getpwnam {
	my ($strUser) = @_;

	# WRONG!!
	#if ($^O =~ /linux/i) {
	#	return ::getpwnam($strUser);
	#}

	my $dbConn = new eFolder::Database(UASDatabaseAddress);
	my $query = "select NAME_COL,'*' as PASS,IDX_COL+10000 as UID_COL,IDX_COL+10000 as GID_COL, 0 as QUOTA_COL, '' as COMMENT_COL, FLNAME_COL,HOMEDIR_COL,SHELL_COL from ACT_TBL";

	if ($strUser) {
		$query .= " where NAME_COL = '$strUser'";
	}

	$dbConn->Sql($query);
	#print STDERR $query, "\n";

	if ($dbConn->IsError()) {
		$dbConn->Close();
		return ERROR;
	}

	my @row = ();
	if ($dbConn->FetchRow()) {
		@row = ($dbConn->Data("NAME_COL"), 
			$dbConn->Data("PASS"), 
			$dbConn->Data("UID_COL"), 
			$dbConn->Data("GID_COL"),
			$dbConn->Data("QUOTA_COL"),
			$dbConn->Data("COMMENT_COL"),
			$dbConn->Data("FLNAME_COL"),
			$dbConn->Data("HOMEDIR_COL"),
			$dbConn->Data("SHELL_COL"));
	}
	$dbConn->Close();

	#print STDERR join("||", @row), "\n";

	return @row;
}


sub test{
	print STDERR join("^", eFolder::UASHelper::getpwnam("Admin")), "\n";
}

#test();


1;
