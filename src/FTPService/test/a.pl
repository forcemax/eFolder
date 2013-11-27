my @arrProfile = getpwnam("chunsj");

if(defined(@arrProfile)){
	print "Defined";
}else{
	print "Undefined";
}

