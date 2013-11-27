#!/usr/bin/perl -w

package eFolder::DNSLib;
use strict;
use POSIX qw(strftime);

sub ERROR               { return        -1;}
sub SUCCESS             { return        1;}
sub FAIL                { return        0;}

sub GetHost; *DNSLib::GetHost = \&DNSLib::_GetHostLA;

sub new{
	my($class, $option, $debug) = @_;

	my ($strUserID) = split(/\&/, $ENV{'REQUEST_URI'});
	my ($tmp , $userid) = split(/\=/, $strUserID);

#	print STDERR "UserID: $userid \n";
	if (!$userid) { $userid='anon'; }
	my $self = ();
	   $self->{strServerList} = "/tmp/server.dat";
	   $self->{UPDATEDATA} = "/tmp/update.dat";
	   $self->{JAVAUPDATEDATA} = "/tmp/updatej.dat";
	   $self->{DOWN_server} = "";
	   $self->{UP_server} = "";
	   $self->{FOLDER_server} = "";
	   $self->{nErrCode} = "";
	   $self->{strErrString} = "";
	   $self->{userid} = $userid;
	 
	bless $self, $class;
}


sub _GetHostLA {
	my($self) = @_;
	my $line = $self->{strServerList};
	my @arrGroupType = ();
	my %hashGroup = ();
	my @arrValue = ();

	my $i = 0;
	my @FOLDER = ();
	my @UP = ();
	my @DOWN = ();
	my %hashUser = ();
#my $StartTime = time();
	
	if (! open(INFILE, $line)) {
		$self->{nErrCode} = "-100";
		$self->{strErrString} = "File " . 
			$self->{strServerList} . " cannot be opened!";
		print STDERR sprintf("[%s] ERROR: %s\n",strftime("%Y-%m-%d %H:%M:%S", localtime()),$self->{strErrString});
		return FAIL;
	}

	# Read File
	my $ref_arrTemp ;
	my $cnt = 0;
	my $myGroupCode = "";
	while ($line=<INFILE>) {
        	$line =~ s/[\n\r]//g;
		if( $line eq "") { next; } 

		my @arrItem = split(/:/, $line);
		if( $arrItem[0] eq "GROUP"){
			push ( @arrGroupType, $arrItem[1]);
			$myGroupCode = $arrItem[1];
		}elsif( $arrItem[0] =~ /USER/){
			my @arrUser = ();
			if( !defined($hashUser{$myGroupCode})){ 
				$hashUser{$myGroupCode} = \@arrUser;
			}
			my $ref_arrUser = $hashUser{$myGroupCode};
			push(@$ref_arrUser, $arrItem[1]);	
		}else{	
			$hashGroup{$arrItem[0]} = $arrItem[1];			
		}
		
	}

# Close File
	if (! close(INFILE)) {
		$self->{nErrCode} = "-200";
		$self->{strErrString} = "File " . 
			$self->{strServerList} . " cannot be closed!";
		
		print STDERR sprintf("[%s] ERROR: %s\n",strftime("%Y-%m-%d %H:%M:%S", localtime()),$self->{strErrString});
		return FAIL;
	}

	my @arrKey = ();
	foreach my $myGroup (@arrGroupType){
		my $KeyFolder = $myGroup."FOLDER";
		push( @arrKey, $KeyFolder );

		my $KeyDown = $myGroup."DOWN";
		push( @arrKey, $KeyDown );

		my $KeyUp = $myGroup."UP";
		push( @arrKey, $KeyUp );

		@DOWN = split(/,/, $hashGroup{$KeyDown});
		@UP = split(/,/, $hashGroup{$KeyUp});
		@FOLDER = split(/,/, $hashGroup{$KeyFolder});
		
		if ($#DOWN < 0 || $#UP < 0) {
        	        $self->{nErrCode} = "-300";
                	$self->{strErrString} = "Active Server is Nothing\n";
			print STDERR sprintf("[%s] ERROR: %s\n",strftime("%Y-%m-%d %H:%M:%S", localtime()),$self->{strErrString});
			
			return FAIL;
	        }
	
#		print STDERR "FOLDER: ".join(",", @FOLDER)."\n";
#		print STDERR "DOWN: ".join(",", @DOWN)."\n";
#		print STDERR "UP: ".join(",", @UP)."\n";
		my $secTime = sprintf(strftime("%S", localtime()));
		my $factorD = 0.33;
		my $factorF = 0.75;
		my $factorU = 0.75;

		if (0) {
		# normal.  
		} elsif ($secTime % 3 == 0) {
			# busy
			$factorD = 1/5; 
		#	$factorF = 0.40;
		#	$factorU = 0.40;
		} elsif ($secTime % 4) {
			$factorD = 1/3;
		#	$factorF = 0.60;
		#	$factorU = 0.60;
		} else {
			$factorD = 1/2;
		#	$factorF = 0.80;
		#	$factorU = 0.80;
		}
		my $DOWN_thresh = $factorD*$#DOWN; 
		my $UP_thresh = $factorU*$#UP; 
		my $FOLDER_thresh = $factorF*$#FOLDER; 
		
   		my $DOWN_idx = int(rand(1000))%($DOWN_thresh+1);
   		my $UP_idx = int(rand(1000))%($UP_thresh+1);
   		my $FOLDER_idx = int(rand(1000))%($FOLDER_thresh+1);
		
#		print STDERR sprintf("DOWN_idx:%s, UP_idx:%s, FOLDER_idx:%s\nDOWN_cnt:%s, UP_cnt:%s, FOLDER_cnt:%s\n",$DOWN_idx,$UP_idx,$FOLDER_idx,$DOWN_thresh,$UP_thresh,$#FOLDER);
#		print STDERR "SERVER: @UP"."\n";
		$self->{DOWN_server} = $DOWN[$DOWN_idx];
		$self->{UP_server} = $UP[$UP_idx];
		$self->{FOLDER_server} = $FOLDER[$FOLDER_idx];
		
      		my $USER = $hashUser{$myGroup};
		foreach my $item (@$USER){
      	  	        if( $item =~ /^$self->{userid}/){
          	              my @arrItem = split(/\t/, $item);
          	              $self->{UP_server} = $arrItem[1];
          	              $self->{DOWN_server} = $arrItem[2];
          	              $self->{FOLDER_server} = $arrItem[3];
          	              last;
          		}
        	}

	
		#print STDERR sprintf("[%s] %s/%s/%s/%s/%s/%s\n",strftime("%Y-%m-%d %H:%M:%S", localtime()),$ENV{"REMOTE_ADDR"},$self->{userid}, $myGroup, $self->{DOWN_server},$self->{UP_server}, $self->{FOLDER_server});
		
		#my $DOWN_addr = (gethostbyname("$self->{DOWN_server}.embian.com"))[4];
		#$self->{$KeyDown} = join(".", unpack('C4', $DOWN_addr));
		my $DOWN_addr = "$self->{DOWN_server}";
		$self->{$KeyDown} = $DOWN_addr;
		#my $UP_addr = (gethostbyname("$self->{UP_server}.embian.com"))[4];
		#$self->{$KeyUp} = join(".", unpack('C4', $UP_addr));
		my $UP_addr = "$self->{UP_server}";
		$self->{$KeyUp} = $UP_addr;
		#my $FOLDER_addr = (gethostbyname("$self->{FOLDER_server}.embian.com"))[4];
		#$self->{$KeyFolder} = join(".", unpack('C4', $FOLDER_addr));
		my $FOLDER_addr = "$self->{FOLDER_server}";
		$self->{$KeyFolder} = $FOLDER_addr;
	
			
		############################################################	
	}

#	print STDERR "KEY:".join(",", @arrKey)."\n";
	$self->{REF_ARRKEY} = \@arrKey;
	
#my $EndTime = time();
#my $RunTime = $EndTime - $StartTime;

 
	return SUCCESS;
}

sub GetUpdateState {
	my($self) = @_;
	my $ClientVersion = $self->{userid};	
	my @UPDATE = ();

	my $filepath = $self->{UPDATEDATA};

	if (! open(UFILE, $filepath)) {
                $self->{nErrCode} = "-100";
                $self->{strErrString} = "ERROR: File " .
                        $self->{UPDATEDATA} . " cannot be opened!";
                return FAIL;
        }

 	while (my $line=<UFILE>) {
                $line =~ s/[\n\r]//g;
                if( $line eq "") { next; }

                my @arrItem = split(/:/, $line);
                if( $arrItem[0] eq "VER"){
			if( $arrItem[1] <= $ClientVersion ){
				$self->{UPDATESTATE} = "PASS";
				return SUCCESS;
			}else{
				$self->{UPDATESTATE} = "UPDATE";
			}
                }else{
			push( @UPDATE, $line);
                }

        }

	my $factor = 0.75;
	my $UPDATE_thresh = $factor*$#UPDATE;

        my $UPDATE_idx = int(rand(1000))%($UPDATE_thresh+1);

        $self->{UPDATE_server} = $UPDATE[$UPDATE_idx];

	
	if (! close(UFILE)) {
                $self->{nErrCode} = "-200";
                $self->{strErrString} = "ERROR: File " .
                        $self->{UPDATEDATA} . " cannot be closed!";
                return FAIL;
        }

	#my $UPDATE_addr = (gethostbyname("$self->{UPDATE_server}.embian.com"))[4];
	#$self->{UPDATEIP} = join(".", unpack('C4', $UPDATE_addr));
	my $UPDATE_addr = "$self->{UPDATE_server}";
	$self->{UPDATEIP} = $UPDATE_addr;

	print STDERR sprintf("[%s] update/%s/%s/%s\n",strftime("%Y-%m-%d %H:%M:%S", localtime()),$ENV{"REMOTE_ADDR"},$self->{UPDATE_server},$self->{UPDATEIP} );
	
	return SUCCESS;

}

sub GetJavaUpdateState {
	my($self) = @_;
	my $ClientVersion = $self->{userid};	
	my @UPDATE = ();

	my $filepath = $self->{JAVAUPDATEDATA};

	if (! open(UFILE, $filepath)) {
                $self->{nErrCode} = "-100";
                $self->{strErrString} = "ERROR: File " .
                        $self->{JAVAUPDATEDATA} . " cannot be opened!";
                return FAIL;
        }

 	while (my $line=<UFILE>) {
                $line =~ s/[\n\r]//g;
                if( $line eq "") { next; }

                my @arrItem = split(/:/, $line);
                if( $arrItem[0] eq "VER"){
			if( $arrItem[1] <= $ClientVersion ){
				$self->{UPDATESTATE} = "PASS";
				return SUCCESS;
			}else{
				$self->{UPDATESTATE} = "UPDATE";
			}
                }else{
			push( @UPDATE, $line);
                }

        }

	my $factor = 0.75;
	my $UPDATE_thresh = $factor*$#UPDATE;

        my $UPDATE_idx = int(rand(1000))%($UPDATE_thresh+1);

        $self->{UPDATE_server} = $UPDATE[$UPDATE_idx];

	
	if (! close(UFILE)) {
                $self->{nErrCode} = "-200";
                $self->{strErrString} = "ERROR: File " .
                        $self->{UPDATEDATA} . " cannot be closed!";
                return FAIL;
        }

	#my $UPDATE_addr = (gethostbyname("$self->{UPDATE_server}.embian.com"))[4];
	#$self->{UPDATEIP} = join(".", unpack('C4', $UPDATE_addr));
	my $UPDATE_addr = "$self->{UPDATE_server}";
	$self->{UPDATEIP} = $UPDATE_addr;

	print STDERR sprintf("[%s] update/%s/%s/%s\n",strftime("%Y-%m-%d %H:%M:%S", localtime()),$ENV{"REMOTE_ADDR"},$self->{UPDATE_server},$self->{UPDATEIP} );
	
	return SUCCESS;

}

sub _main{
	my $dns = new eFolder::DNSLib();	
	$dns->GetHost() || die $dns->{strErrString};

	my $ref_arrKey = $dns->{REF_ARRKEY} ;
	print STDERR $#$ref_arrKey."\n";

}	
	

#_main();

1;
	
