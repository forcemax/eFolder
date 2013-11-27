#!/usr/bin/perl
use mCGI;

$objCGI = new mCGI;
$objCGI->Parse();
$objCGI->HttpHeader();

$objCGI->printParameterAll();
#$objCGI->printENV();
print $objCGI->GetUploadFileName();

$objStreamBuffer = $objCGI->GetStreamBuffer();
if(!defined($objStreamBuffer)){
print STDERR "StreamBuffer is not defined\n";
	exit;
}

open (OUTPUT, "> a.exe");
binmode OUTPUT;

while(defined($strData = $objStreamBuffer->ReadStream())) {
	print OUTPUT $strData;
}
close(OUTPUT);


