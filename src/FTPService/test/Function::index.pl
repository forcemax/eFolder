#!/usr/bin/perl
$strTemp = "asdfafafa\r\n\r\n 1234";
$CRLF = "\r\n";
$ok = 0;
$ok ++ if  ($end =index($strTemp, "${CRLF}${CRLF}")) >0;
#print $ok;
print index($strTemp, "$CRLF$CRLF");

$byte = read(10, $buffer, 10,0);
if(defined($byte)) {
	print "byte";

}
if(defined($buffer), 10, 0){
	print "buffer";
}
if(1){
	print "1\n";
}

if(2) {
	print "2\n";
}

