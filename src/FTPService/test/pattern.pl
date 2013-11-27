$a = "d:\\this:\\gogo\\hjpark\\gg" ;
$a =~ s/\\/\//g;

print $a, "\n";
if($a =~ /(.*):\/(.*)/){
	print $1;
print "\n";
print $2;
print "\n";
}
