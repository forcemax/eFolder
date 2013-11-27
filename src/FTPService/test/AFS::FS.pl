#!/usr/bin/perl
#디렉토리에 대한 quota는 undefined

use AFS::FS qw(getquota);
my $quota = getquota("/afs/embian.gnu/home/hjpark");
if($quota == ""){
	print "qutota is null\n";
}

if(defined($quota)){
	print "quota is defined \n";
}else{
	print "quota is undefined \n";
}

if($quota) {
	print "true\n";
}else{
	print "false\n";
}


print "hjpark 's qutoa is : $quota \n";
$quota = getquota("/afs/embian.gnu/home/chunsj/AFS Developers");
print "share qutoa is : $quota \n";
$quota = getquota("/afs/embian.gnu/home/chunsj");
print "chunsj's qutoa is : $quota \n";


