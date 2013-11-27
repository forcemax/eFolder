#!/usr/bin/perl 
package eFolder::FileSystem;
use strict;
#use eFolder::FileSystemAFS;
use File::Path;
use eFolder::CONSTANT;
use eFolder::CONFIG;
use SOAP::Lite;
use MIME::Base64 qw(encode_base64);
#use Text::Iconv;
use eFolder::Account;
use POSIX qw(strftime floor);
use Date::Calc qw(Delta_Days);

sub new{
	my ($class) = @_;
	my $self = ();
	$self->{nErrorCode} = NO_ERROR;
	$self->{strError} = 0;
	bless $self, $class;
}

sub FixEncoding{
	my $string = shift;

    	my $buf = "";
	open (MEM, ">", \$buf);
	print MEM $string;
	close(MEM);

	$string = pack "U0C*", unpack "C*", $buf;
	$buf = pack "C*", unpack "U0C*", $string;
	
	return $buf;
}

sub GetErrorCode{
	my ($self) = @_;
	return $self->{nErrorCode} ;
}

sub GetError{
	my($self) = @_;
	return ($self->{nErrorCode}, $self->{strError});
}

sub MakeDirectory{
	my($self, $strTargetPath) = @_;
	my $nResult = mkdir($strTargetPath);

	$self->{nErrorCode} = NO_ERROR;
	if($nResult == 0){
		$self->{strError} = int($!);
		$self->{nErrorCode} = OS_ERROR;
		return ERROR;
	} 
	return SUCCESS;
}

sub MakeDirectoryAll{
        my($self, $strTargetPath) = @_;

# Recursive MakeDirectory
# $strRealPath = "/eFolder/embian4/tin03/a/b/c";
        #print STDERR  "JJHWANG2:FileSystem.pm: $strTargetPath\n";


        my @dir = split(/\//, $strTargetPath);
        my $prefix = join("/", @dir[0..1]);

        for (my $i=2; $i <= $#dir; $i++) {
                my $cur_dir =  $prefix . "/" . $dir[$i];
                my $nResult = 1;
                $nResult = mkdir $cur_dir if (! -d $cur_dir);
                #print STDERR sprintf("mkdir($cur_dir)=$nResult\n");
                if (!$nResult) {
                        $self->{strError} = int($!);
                        $self->{nErrorCode} = OS_ERROR;
                        return ERROR;
                }
                $prefix =  $cur_dir;
        }
        return SUCCESS;
}

sub DeleteDirectory{
	my ($self, $strTargetPath) = @_;

	my $nResult = rmtree($strTargetPath);

	if($nResult == 0){
		$self->{strError} = int($!);
		$self->{nErrorCode} = OS_ERROR;
		return ERROR;
	}
	return SUCCESS;

}

sub DeleteFile{
	my ($self, $strTargetPath) = @_;

	my $nResult = unlink($strTargetPath) ;
	if($nResult == 0){
		$self->{strError} = int($!);
		$self->{nErrorCode} = OS_ERROR;
		return ERROR;
	}
	return SUCCESS;
}

sub Rename{
	my ($self, $strOldPath, $strNewPath) = @_;

	if (-e $strNewPath) {
		$self->{strError} = "File Path Already Exists"; 
		$self->{nErrorCode} = OS_ERROR;
		return ERROR;
	}
	my $nResult = rename($strOldPath, $strNewPath);

	if($nResult == 0){
		$self->{strError} = int($!);
		$self->{nErrorCode} = OS_ERROR;
		return ERROR;
	}

	return SUCCESS;
}

sub DaysLeft{ 
        my ($ndate) = @_; 
        my @arrNow=split(/_/, strftime("%Y_%m_%d", localtime)); 
        my @arrDate=split(/_/, strftime("%Y_%m_%d", localtime($ndate)));

        my $days = Date::Calc::Delta_Days(0+$arrDate[0],0+$arrDate[1],0+$arrDate[2], 0+$arrNow[0],0+$arrNow[1],0+$arrNow[2]);

        if (0+eFolder_MAX_FREE_DAY() - $days < 0) {
                return 0;
        }
        return  (0+eFolder_MAX_FREE_DAY() - $days);
}


sub isValidFile{
	my ($strFileName, $IsMine) = @_;
	if ($strFileName eq '.') {
		return 0;
	}elsif($strFileName eq '..') {
		return 0;
	}elsif(encode_base64($strFileName,"") eq "6rCc7J247Y+0642U" && $IsMine eq 0){
		return 0;
	}else{
		return 1;
	}
}

sub ListDirectory3{
        my ($self, $strTargetPath, $IsMine, $GroupCode,  $ref_arrDirList) = @_;

        my @arrStat = ();
        my $i = 0;
        my $nDays = 0;

        my $nResult = opendir hDIR, $strTargetPath;
        if($nResult == 0){
                $self->{strError} = int($!);
                $self->{nErrorCode} = OS_ERROR;
                do_debug("opendir is failed : ($strTargetPath) $!");
                return FAIL;
        }

        while(my $strFileName = readdir(hDIR)){
                if(isValidFile($strFileName, $IsMine) == 1){
			my $tempPath = $strTargetPath . "/" . $strFileName ;
			$tempPath = FixEncoding($tempPath);
                        @arrStat = stat($tempPath) ;

                        $$ref_arrDirList[$i]{Name} = $strFileName." ";
                        $$ref_arrDirList[$i]{FileSize} = $arrStat[7];

                        if(!$$ref_arrDirList[$i]{FileSize}){
                                $$ref_arrDirList[$i]{FileSize} = 0
                        }

                        $$ref_arrDirList[$i]{CreateTime} = ToDateString($arrStat[8]);
                        $$ref_arrDirList[$i]{ModifyTime} = ToDateString($arrStat[9]);
                        $$ref_arrDirList[$i]{AvailableTime} = DaysLeft($arrStat[9]);
	
                        if( -d $strTargetPath."/".$strFileName){
                                $$ref_arrDirList[$i]{FileType} = "Directory";
                        }else{
                                $$ref_arrDirList[$i]{FileType} = "File";
                        }

                        $$ref_arrDirList[$i]{GroupCode} = $GroupCode;

                        $i ++;
                }
        }
        closedir(hDIR);

        return SUCCESS;
}


sub UnknownVolume{
	my ($strVolumeName) = @_;
	my %hashReturn;
	 $hashReturn{VolumeName} = $strVolumeName;
	 $hashReturn{VolumeType} = 9;
	 $hashReturn{TotalSize} = 0;
	 $hashReturn{AvailableSpace} =0;
	return \%hashReturn;
}

sub UnAuthorizedVolume{
	my ($self, $strVolumeName) = @_;
   my %hashReturn;
    $hashReturn{VolumeName} = $strVolumeName;
    $hashReturn{VolumeType} = 8;
    $hashReturn{TotalSize} = 0;
    $hashReturn{AvailableSpace} = 0;
   return \%hashReturn;
}

sub GetVolumeStats_Aux {
	my($self, $strTargetPath, $strVolumeName) = @_;
	if($strTargetPath eq ""){
		return undef;
	}

	my %hashReturn;

	$hashReturn{VolumeName} = $strVolumeName;
	$hashReturn{VolumeType} = 6;  # no Link
	$hashReturn{TotalSize} =  0;
	$hashReturn{AvailableSpace} = 0;
	return \%hashReturn;
}

sub GetVolumeStats{
	my($self, $strTargetPath, $strVolumeName) = @_;
	if($strTargetPath eq ""){
		return undef;
	}
	
	my %hashReturn;

	if( -d $strTargetPath ) {
#		print STDERR "FileSystem.pm::GetVolumeStats Unknown Volume $strTargetPath  $strVolumeName  \n";
        	return UnknownVolume($strVolumeName);
    	}else{
        	$self->{nErrorCode} =  AFS_ERROR;
        	$self->{strError} =  "Fail to GetVolstats( $strTargetPath )";
        	print STDERR "FileSystem.pm::GetVolumeStats Fail to GetVolstats $strTargetPath $strVolumeName \n";
        	return  undef;
    	}

	$hashReturn{VolumeName} = $strVolumeName;
    	chop($strTargetPath);
    	if(-l $strTargetPath){
        	$hashReturn{VolumeType} = 7;
    	}else{
        	$hashReturn{VolumeType} = 6;
    	}

    	$hashReturn{TotalSize} = 999999999999;
    	$hashReturn{AvailableSpace} = 999999999999;

	return \%hashReturn;
}

sub GetFileAttribute{
	my ($self, $strTargetPath) = @_;
	my @arrStat=();
	my %hashFileAttr; 

	my @arrFilePath = split(/\//, $strTargetPath);
	my $strFileName  = $arrFilePath[$#arrFilePath];

	if(! -e $strTargetPath) {
		$self->{strError} = int($!);
		$self->{nErrorCode} = OS_ERROR;
		do_debug("FileSystem.pm::GetFileAttribute( $strTargetPath )  $! ");
		return;
	}

	@arrStat = stat($strTargetPath);

	if(-d $strTargetPath) {
		$hashFileAttr{FileType} = "Directory";
	}else{
		$hashFileAttr{FileType} = "File";
	}
	$hashFileAttr{Name} = $strFileName;
	$hashFileAttr{FileSize} = $arrStat[7];

	if(!$hashFileAttr{FileSize}){
		$hashFileAttr{FileSize} = 0;
	}

	$hashFileAttr{CreateTime} = ToDateString($arrStat[8]);
	$hashFileAttr{ModifyTime} = ToDateString($arrStat[9]);
	return \%hashFileAttr;
}

sub ToDateString{
	my ($ndate) = @_;
	my $strDateString="";
	my @arrDateString = ();
	@arrDateString = localtime($ndate);
	$strDateString = (1900 + $arrDateString[5])."-". ($arrDateString[4] + 1) ."-"
			.$arrDateString[3]." ".$arrDateString[2].":".$arrDateString[1].":".$arrDateString[0];
	return $strDateString;
}

sub CreateRealDestPath{
	my ($strSrc, $strDest) = @_;
	my @arrPath = split(/\//, $strSrc);
	my $strPostfix = $arrPath[$#arrPath];
	my $strRealDestPath = $strDest . $strPostfix;
	while( -e $strRealDestPath){
		$strPostfix = CONST_DUPLICATED_COPY . $strPostfix ;
		$strRealDestPath = $strDest . $strPostfix ;
	}
	return $strRealDestPath;
}
		

sub GetCopyProgressSize{
	my($self, $strPath, $strDestPath) = @_;
	my $strCopyPath = $strPath . "." .$strDestPath;
	print STDERR "GetCopyProgressSize:" , $strCopyPath, "\n";
	return  GetCopySize($strCopyPath) ;
}

sub test {
}

#test();

1;
