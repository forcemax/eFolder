#!/usr/bin/perl
#
package eFolder::SOAPHelper;
use strict;

sub new {
	my ($class) = @_;
	my $self = ();
	$self->{strError} = "";

	bless $self, $class;
}


sub MakeEchoResponse {
	my($self, $ref_arrEchoList) = @_;
	my @arrSoapData = ();
	my $i = 0;
	return SOAP::Data->type('ArrayOf_Any')->name('ArrayOf_Any')->value($ref_arrEchoList);
}

sub MakeVolumeListResponse{
	my($self, $ref_arrVolumeList) = @_;
	my @arrSoapData = ();
	my $i = 0;
	for($i = 0; $i<= $#$ref_arrVolumeList ; $i ++){
		$arrSoapData[$i] = SOAP::Data->type("_RemoteDrive")->name("_RemoteDrive")->value($$ref_arrVolumeList[$i]);
	}
	return SOAP::Data->type('ArrayOf_RemoteDrive')->name('ArrayOf_RemoteDrive')->value(\@arrSoapData);
}

sub MakeDirListResponse3{
        my ($self, $ref_arrDirList) = @_;
        my @arrSoapData=();
        my $i =0;

        for($i = 0 ; $i <= $#$ref_arrDirList ; $i ++){
                my %DirHash ;
                $DirHash{Name} =  $$ref_arrDirList[$i]{Name};
                $DirHash{FileSize} = $$ref_arrDirList[$i]{FileSize};
                $DirHash{FileType} = $$ref_arrDirList[$i]{FileType};
                $DirHash{CreateTime} = $$ref_arrDirList[$i]{CreateTime};
                $DirHash{ModifyTime} = $$ref_arrDirList[$i]{ModifyTime};
                $DirHash{AvailableTime} = $$ref_arrDirList[$i]{AvailableTime};
                $DirHash{GroupCode} = $$ref_arrDirList[$i]{GroupCode};

                $arrSoapData[$i] = SOAP::Data->type("_RemoteFile3")->name("_RemoteFile3")->value(\%DirHash);
        }

#       return SOAP::Data->type('Array')->value(\@arrSoapData);
        return SOAP::Data->type('ArrayOf_RemoteFile3')->name('ArrayOf_RemoteFile3')->value(\@arrSoapData);
}

sub MakeFileAttributeResponse{
	my ($self, $ref_hashFileAttr) = @_;
	return SOAP::Data->type("_RemoteFile")->name("_RemoteFile")->value($ref_hashFileAttr);
}

sub MakeProfile2Response{
        my ($self, $ref_hashFileAttr) = @_;
        my @arrSoapData=();
        my $i =0;
	
	return SOAP::Data->type("_UserProfile2")->name("_UserProfile2")->value($ref_hashFileAttr);
}

sub MakeGetDriveInfoResponse{
	my ($self, $ref_hashDriveInfo) = @_;
	return SOAP::Data->type("_RemoteDrive")->name("_RemoteDrive")->value($ref_hashDriveInfo);
}

sub MakeFindFilesResponse{
	my ($self, $ref_arrFileList) = @_;
	my @arrSoapData = ();

	if($#$ref_arrFileList >= 0) {
		 my $i = 0;
		 for( $i=0 ; $i <=$#$ref_arrFileList; $i++){
			my %hashFileInfo = (); 
			$hashFileInfo{FileName} = $$ref_arrFileList[$i]{FileName};
			$hashFileInfo{FileSize} = $$ref_arrFileList[$i]{FileSize};
			$hashFileInfo{FileOwner} = $$ref_arrFileList[$i]{FileOwner};
			$hashFileInfo{FilePath} = $$ref_arrFileList[$i]{FilePath};
			$arrSoapData[$i] = SOAP::Data->type("_FileInfo")->name("_FileInfo")->value(\%hashFileInfo);
		}
		return SOAP::Data->type('ArrayOf_FileInfo')->name('ArrayOf_FileInfo')->value(\@arrSoapData);
	}
}

sub MakeFindFilesResponse2{
	my ($self, $ref_arrFileList) = @_;
	my @arrSoapData = ();

	if($#$ref_arrFileList >= 0) {
		 my $i = 0;
		 for( $i=0 ; $i <=$#$ref_arrFileList; $i++){
			my %hashFileInfo = (); 
			$hashFileInfo{FileIndex} = $$ref_arrFileList[$i]{FileIndex};
			$hashFileInfo{FileName} = $$ref_arrFileList[$i]{FileName};
			$hashFileInfo{FileSize} = $$ref_arrFileList[$i]{FileSize};
			$hashFileInfo{FileOwner} = $$ref_arrFileList[$i]{FileOwner};
			$hashFileInfo{FilePath} = $$ref_arrFileList[$i]{FilePath};
			$hashFileInfo{AvailableTime} = $$ref_arrFileList[$i]{AvailableTime};
			$hashFileInfo{CreateTime} = $$ref_arrFileList[$i]{CreateTime};
			$hashFileInfo{Adult} = $$ref_arrFileList[$i]{Adult};
			$arrSoapData[$i] = SOAP::Data->type("_FileInfo2")->name("_FileInfo2")->value(\%hashFileInfo);
		}
#		return SOAP::Data->type('Array')->value(\@arrSoapData);
		return SOAP::Data->type('ArrayOf_FileInfo2')->name('ArrayOf_FileInfo2')->value(\@arrSoapData);
	}
}

1;
