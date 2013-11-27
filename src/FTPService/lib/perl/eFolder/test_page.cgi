#!/usr/bin/perl
use strict;

########## Start Procedure ####################################
print "Content-Type: text/plain; charset=utf-8\n\n";
print "* FTPService  테스트 페이지 입니다!\n";
print "* 날짜:" . `date +'%Y-%m-%d %H:%M:%S'`;
print "* IP: ". $ENV{"REMOTE_ADDR"} ;
