#!/usr/bin/perl
use strict;
use AFS::KTC_EKEY;
use AFS::KTC_TOKEN;

sub dummy{
my $user = AFS::KTC_PRINCIPAL->new("s01user");
my $ok = AFS::KTC_TOKEN->UserAuthenticateGeneral($user, "embian", 60*60*24,
	&AFS::KA_USERAUTH_VERSION | &AFS::KA_USERAUTH_DOSETPAG);

print $ok;

my $i = 0;
print "start\n";
	while(1){
		sleep(1);
		print " $i : ";
		$i ++;
		if( -e "/afs/folderplus.com/eFolder/Public/hjpark/a.pl"){
			open EP, "/afs/embian.gnu/home/hjpark/a.pl";
			print "success";
			close EP;
		}else{
			print "fail";
		}
print "\n";
	}
}

dummy;
