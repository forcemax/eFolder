#!/usr/bin/perl
package eFolder::CONSTANT;
use strict;
use Exporter();

use vars qw(@ISA @EXPORT);
@ISA =  qw(Exporter);
@EXPORT = qw(ERROR SUCCESS FAIL NO_ERROR OS_ERROR AFS_ERROR 
			DUPLICATE_ERROR
			THUMB_MATCHED
			_DEBUG);

sub ERROR		{ return 	-1;}
sub SUCCESS		{ return 	1;}
sub FAIL		{ return 	0;}
sub NO_ERROR		{ return 	2;}

sub OS_ERROR		{ return 	1001;}
sub AFS_ERROR		{ return	1002;}
sub THUMB_MATCHED	{ return 	9001;}
sub DUPLICATE_ERROR	{ return 	9002;}
sub _DEBUG		{ return 	1;}

1;
