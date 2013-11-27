#!/usr/bin/perl
package eFolder::FileFinder;
use strict;
use eFolder::CONFIG;
use eFolder::CONSTANT;
use eFolder::Database;
use Time::Local;
use Time::HiRes;
use POSIX qw(strftime floor);
use Date::Calc qw(Delta_Days);

sub new{
	my($class) = @_;
	my $self =();
	   $self->{strError} = "";
	   $self->{hDB} = new eFolder::Database(FileDatabaseAddress);
	bless $self, $class;
}

sub FindFiles2{
	#          어떻게?,    무엇을?,  어디서부터, 성인보여주나?, 성인인지?, 리턴.
	my($self, $strWhat, $strPattern, $nStart, $bBlock, $strVolumeNameList, $ref_arrFileList) = @_;
	my $dbConn = $self->{hDB}; 

	my $tStartTime = Time::HiRes::time();
	my $query;	

	my $strUTF8 = pack "U0C*", unpack "C*", $strPattern;
	do_debug("Before pattern conv. : $strPattern");
	do_debug("After pattern conv. : $strUTF8");

	my $lTotal = 0;
	my @id_list = (-1);
	
	use Sphinx::Search;
	my $spx = Sphinx::Search->new;

	$spx->SetServer('localhost', 9312);

	$spx->SetLimits($nStart, MAX_RESULT_SIZE, 1000000);

	$spx->SetFilter("updated", [0, 1]);
	my $results = $spx->Query($strUTF8, "FileList, delta");

	$lTotal = $results->{total_found};

	foreach my $match (@{$results->{matches}}) {
		push(@id_list, $match->{doc});
	}

	$query = "SELECT * FROM FileList WHERE id in ("
            . join(",", @id_list) . ")"; # AND FileOwner in $strVolumeNameList";

	do_debug("query : $query");

	$query =~ s/\\/\\\\/g;
	$dbConn->Sql($query);

	if($dbConn->IsError()){
		$self->{strError} = $dbConn->getErrMsg();
		$dbConn->Close();
		return FAIL;
	}
	     
	$$ref_arrFileList[0]{FileIndex} = "id ";
	$$ref_arrFileList[0]{FileName} = "Search Result ";
	$$ref_arrFileList[0]{FileSize} = $lTotal;
	$$ref_arrFileList[0]{FilePath} = "Search:" . $strPattern;
	$$ref_arrFileList[0]{FileOwner} = "FileFinder";
	$$ref_arrFileList[0]{AvailableTime} = 0;
	$$ref_arrFileList[0]{Adult} = 0;
	
	my $i = 1;
	my $nDaysLeft = 0;
	my @arrFileKey = ();
	my $strFileKey = "";
	my %hashAdultKey = ();

	while($dbConn->FetchRow()){
		$nDaysLeft = $self->DaysLeft($dbConn->Data("CreateTime"));

		$$ref_arrFileList[$i]{FileIndex} = $dbConn->Data("FileKey");
		$$ref_arrFileList[$i]{FileName} = "xsd:string".$dbConn->Data("FileName");
		$$ref_arrFileList[$i]{FileSize} = $dbConn->Data("FileSize");
		$$ref_arrFileList[$i]{FilePath} = "xsd:string".$dbConn->Data("FilePath");
		$$ref_arrFileList[$i]{FileOwner} = "xsd:string". $dbConn->Data("FileOwner");
		$$ref_arrFileList[$i]{AvailableTime} = $nDaysLeft;
		$$ref_arrFileList[$i]{CreateTime} = strftime("%Y-%m-%d %H:%M:%S", localtime($dbConn->Data("CreateTime")));
		if( $dbConn->Data("Adult") eq "A") {
			$$ref_arrFileList[$i]{Adult} = 1;
		} else {
			$$ref_arrFileList[$i]{Adult} = 0;
		}
	
		$strFileKey = $dbConn->Data("FileKey");
		$strFileKey = $dbConn->Quote($strFileKey);

		push(@arrFileKey, $strFileKey);

		$hashAdultKey{$dbConn->Data("FileKey")} = $i;
		$i ++;
	}
	
	$dbConn->Close();
	
	my $tEndTime = Time::HiRes::time();
	my $QTime = $tEndTime - $tStartTime;
	
	return SUCCESS;
}

sub DaysLeft{
        my ($self, $ndate) = @_;
        my @arrNow=split(/_/, strftime("%Y_%m_%d", localtime));
        my @arrDate=split(/_/, strftime("%Y_%m_%d", localtime($ndate)));

        my $days = Date::Calc::Delta_Days(0+$arrDate[0],0+$arrDate[1],0+$arrDate[2], 0+$arrNow[0],0+$arrNow[1],0+$arrNow[2]);

        if (0+eFolder_MAX_FREE_DAY() - $days < 0) {
                return 0;
        }
        return  (0+eFolder_MAX_FREE_DAY() - $days);
}


sub IsVetoedWord{
	my ($self, $strWord) = @_;

	my $dbConn = $self->{hDB};
	my $query = "SELECT COUNT(*) as VETOED FROM eFolder_Veto WHERE Veto = lower('$strWord')";
	$query =~ s/\\/\\\\/g;

	$dbConn->Sql($query);

	if($dbConn->IsError()){
		$self->{strError} = $dbConn->getErrMsg();
		$dbConn->Close();
		return undef;
	}

	$dbConn->FetchRow();
	
	my $bExists = $dbConn->Data("VETOED");


	if($bExists > 0) {
		return 1;
	}else{
		return 0;
	}
}



sub SetAdult_Single {
        my($self, $strFileKey, $strUserName, $dbConn) = @_;


	$strFileKey = $dbConn->Quote($strFileKey);

        my $query = "SELECT AdultHit, HitUserQueue FROM AdultList WHERE FileKey=$strFileKey";
	
        $dbConn->Sql($query);
        if($dbConn->IsError()){
                $self->{strError} = $dbConn->getErrMsg();
                $dbConn->Close();
                return 0;
        }

        my $bExist = $dbConn->FetchRow();

        if( defined($bExist) ){
                my $strHitUser = $dbConn->Data("HitUserQueue");
		my @arrHitUser = split(/,/ , $strHitUser);

		if( $#arrHitUser > 20 ){
			return -1;
		}

                foreach my $strUser (@arrHitUser) {
                        if( $strUser eq $strUserName ){
                                return -1;
                        }
                }

		push (@arrHitUser, $strUserName);
                my $strHitUserList = join(",", @arrHitUser) ;
	
                $query = "UPDATE AdultList SET AdultHit=AdultHit+1, LastHitDate=now(), HitUserQueue = '$strHitUserList' WHERE FileKey=$strFileKey"; 

        } else {

		$query = "SELECT FileOwner, FilePath FROM FileList where FileKey=$strFileKey";
		do_debug($query);
		$dbConn->Sql($query);
	        if($dbConn->IsError()){
        	        $self->{strError} = $dbConn->getErrMsg();
               		$dbConn->Close();
	                return 0;
	        }
		$dbConn->FetchRow();
		my $strFileOwner = $dbConn->Quote($dbConn->Data("FileOwner"));
		my $strFilePath = $dbConn->Quote($dbConn->Data("FilePath"));
  		$strUserName = $dbConn->Quote($strUserName);

                $query = "INSERT INTO AdultList VALUES($strFileKey,$strFileOwner,$strFilePath,1,now(),$strUserName)";
        }

        $dbConn->Sql($query);
        if($dbConn->IsError()){
                $self->{strError} = $dbConn->getErrMsg();
                $dbConn->Close();
                return 0;
        }

        
        return 1;

# return 0 ; => 실패
# return 1 ; => 성공
# return -1 ; => 최근 추천한적이 있다.(error)

}

sub SetAdultRegistry {
        my($self, $strFileKey, $strUserName) = @_;
	my $dbConn = $self->{hDB}; 

	my @resultArray = ();
	foreach my $k (split(/\:/, $strFileKey)) {
		my $ret = $self->SetAdult_Single($k, $strUserName,$dbConn);
		if ($ret > 0) {
			push(@resultArray, $k);
		}
	}

        $dbConn->Close();
	return join(":", @resultArray);
}

sub Finalize{
	my ($self) = @_;
	my $dbConn = $self->{hDB};
	$dbConn->Close();
};

	
	
sub main{
#	my @arrFileList = ();
#	my $i = 0;
#	FindFiles2("FileFinder", "Name", "엠비안", 0,1, \@arrFileList);
#	for( $i = 0 ; $i <= $#arrFileList ;  $i ++ ){
#		print "FileName:" . $arrFileList[$i]{FileName} , "\n";
#		print "FileSize:" . $arrFileList[$i]{FileSize} , "\n";
#		print "FilePath:" . $arrFileList[$i]{FilePath} , "\n";
#		print "FileOwner:" . $arrFileList[$i]{FileOwner} , "\n";
#		print "FileKey:" . $arrFileList[$i]{FileIndex} , "\n";
#		print "AvailableTime:" . $arrFileList[$i]{AvailableTime} , "\n";
#		print "Adult:" . $arrFileList[$i]{Adult} , "\n";
#	}

#	my $ret = SetAdultRegistry("FileFinder","Jm2iLFDJBKSYP6sZl7YNGQ:Jm2iLFDJBKSYP6sZl7YNGQ:qzZzx6LmPBUdtfXcokasqQ:to35tjscvsRnPCnArEAM3w:Pkfmj955fGrMGpnOahTM3w","jjjjj");
#	print $ret."\n";
}

sub IsVeto{
	my( $self, $strPattern) = @_;
}



#main;
1;
