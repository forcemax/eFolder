#/usr/bin/perl

use lib qw(/opt/Embian/lib/perl);
use EAM;

if( @ARGV ne 1 ) {
	print STDERR "<< Invalid Argument >>\n";
	print STDERR "Usage : perl deluser.pl [UserName]\n";
	exit(1);
}

my $ret = EAM::DeleteUser("class",$ARGV[0]);

my $sqlCommand = "mysql -hdb -uroot -e \"delete from folderplus.member where id='$ARGV[0]'\" ";

print STDERR "$sqlCommand\n";
system($sqlCommand);
