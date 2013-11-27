#!/usr/bin/perl 
package eFolder::RESOURCE_ENG;
use strict;
use Exporter();

use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(GREETING  OSError 
	AuthenticationFail  CreateSessionFail SessionNotFound  
	UnknownError 
	EmptyData 
	MailSystemError 
	VersionConflict 
	FileSystemError 
	UserProfileNotFound 
	ChangePasswordFail 
	PermissionDenied 
	VetoedWord
	NotEnoughMoney
	IconvFail
	WrongFileName
	RequestAuth
	AccessDenied
	InvalidPasswdLength
	);
sub GREETING		{ return "Hello World";}
sub OSError		{ return (1001, "Operatring System Error");}
sub AuthenticationFail	{ return (1002, "Fail to authentication ");}
sub CreateSessionFail	{ return (1002, "Fail to Create Session");}
sub SessionNotFound	{ return (1003, "Session Data is not found");}
#Error Code 4: Communication Error 
#Error Code 5: Connection Error 
#Error Code 6: Client Cache Error
sub UnknownError	{ return (1007, "Unknown Error"); }
sub EmptyData		{ return (1008, "There are no data to transfer");}
sub MailSystemError	{ return (1009, "Mail System error ");}
sub VersionConflict	{ return (1010, "Version Does Not Match");}
sub FileSystemFail	{ return (1011, "File Service Fail");}
sub UserProfileNotFound	{ return (1012, "User Profile Not Found");}
sub ChangePasswordFail	{ return (1013, "Change Password Fail");}
sub PermissionDenied	{ return (1014, "Permission Denied");}
sub VetoedWord		{ return (1015, "The word is Vetoed ");}
sub NotEnoughMoney	{ return (1016, "Not Enough Money");}
sub WrongFileName	{ return (1017, "Wrong File Name");}
sub InvalidPasswdLength	{ return (1018, "Invalid New Password Length");}
sub IconvFail		{ return (1020, "Character Conversion Fail");}

sub RequestAuth		{ return (1100, "Request Adult Authentication");}
sub AccessDenied	{ return (1101, "Adult Folder Access Denied");}
1;
