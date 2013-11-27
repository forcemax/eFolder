#/usr/bin/perl

use lib qw(/opt/Embian/lib/perl);
use EAM;

if( @ARGV ne 3 ) {
	print STDERR "<< Invalid Argument >>\n";
	print STDERR "Usage : perl adduser.pl [UserName] [UserFullName] [Password]\n";
	exit(1);
}

my  @arrUserInfo = ($ARGV[0], $ARGV[1], "SystemTestUser", $ARGV[2], "0");
my $ret = EAM::AddGarbageUser("class",@arrUserInfo);

print STDERR $ret . "\n";

my $sqlCommand = "mysql -hdb -uroot -e \"insert into folderplus.member(id, passwd, passwd_q, passwd_a, name, reg_num1, reg_num2, email, mdate, coin, charge_num, charge_size, storage) values('$ARGV[0]', '$ARGV[2]', 'q', 'a', '$ARGV[0]','123456' , '1234567', '$user@embian.com', now(), 100000, 0, 0, '0');\""; 

print STDERR "$sqlCommand \n";
system($sqlCommand);
