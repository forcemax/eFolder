#!/usr/bin/perl
package eFolder::IndexerSphinx;
use strict;

use eFolder::CONFIG;
use eFolder::CONSTANT;
use eFolder::RESOURCE_ENG;
use eFolder::Database;
use eFolder::UserObject;
use Digest::MD5;

use Sphinx::Search;

sub new
{
	my($class, $indexerip, $indexerport) = @_;
	my $self = {};

	$self->{spx} = Sphinx::Search->new;
	$self->{spx}->SetServer($indexerip, $indexerport);

	$self->{indexes} = "FileList, delta";

	bless $self, $class;
}

sub sqlEncode
{
    my ($sz) = @_;
    $sz =~ s/'/''/g;
    return $sz;
}

sub DeleteDirectory {
	my ($self, $strTargetDirectory, $objUser) = @_;
	
	my $strVolName = $objUser->GetVolumeNameFromPath($strTargetDirectory);
	my $strVolPath = $objUser->GetVolumePathFromPath($strTargetDirectory);

	my $dbConn = new eFolder::Database(FileDatabaseAddress);

	my $query = "SELECT id FROM FileList WHERE FilePath = '".$strVolPath."' or (FilePath LIKE '".$strVolPath."/%' AND FileOwner = '". $strVolName ."')";
	$dbConn->Sql($query);

	if(! $dbConn->IsError() ) {
		my %id_list = ( -1 => [ 99 ]);
        	while($dbConn->FetchRow()) {
			$id_list{$dbConn->Data("id")} = [ 99 ];	
#			print STDERR "[IndexerSphinx:DeleteDirectory] id : ".$dbConn->Data("id")."\n";
		}
		$query = "DELETE FROM FileList WHERE id in ("
				. join(",", keys %id_list) . ")";
        	$dbConn->Sql($query);
        	$self->{spx}->UpdateAttributes( $self->{indexes}, [ qw/updated/ ], \%id_list );
    	}
    	$dbConn->Close();
}


sub DeleteFile {
        my ($self, $strTargetFile, $objUser) = @_;

        my $strVolName = $objUser->GetVolumeNameFromPath($strTargetFile);
        my $strVolPath = $objUser->GetVolumePathFromPath($strTargetFile);

	my $dbConn = new eFolder::Database(FileDatabaseAddress);

	my $query = "SELECT id FROM FileList WHERE FilePath='".$strVolPath."' AND FileOwner = '". $strVolName ."'";
	$dbConn->Sql($query);

	if(! $dbConn->IsError() ) {
		my %id_list = (-1 => [ 99 ]);
        	while($dbConn->FetchRow()) {
			$id_list{$dbConn->Data("id")} = [ 99 ];	
		}
        	my $query = "DELETE FROM FileList WHERE id in (" .  join(",", keys %id_list) . ")";
        	$dbConn->Sql($query);
        	$self->{spx}->UpdateAttributes( $self->{indexes}, [ qw/updated/ ], \%id_list );
	}
	$dbConn->Close();
}

sub Rename {
	my ($self, $strOldPath, $strNewPath, $objUser) = @_;

	my $strOldVolName = $objUser->GetVolumeNameFromPath($strOldPath);
	my $strOldVolPath = $objUser->GetVolumePathFromPath($strOldPath);
	my $strNewVolName = $objUser->GetVolumeNameFromPath($strNewPath);
	my $strNewVolPath = $objUser->GetVolumePathFromPath($strNewPath);

	my $dbConn = new eFolder::Database(FileDatabaseAddress);

   	my $query = "SELECT id FROM FileList WHERE FilePath = '". $strOldVolPath ."' or (FilePath like '".$strOldVolPath."/%' AND FileOwner = '". $strOldVolName ."')";

    	$dbConn->Sql($query);

	if(! $dbConn->IsError() ) {
		my %id_list = (-1 => [ 99 ]);
        	while($dbConn->FetchRow()) {
			$id_list{$dbConn->Data("id")} = [ 99 ];	
		}
		$query = "UPDATE FileList Set FilePath=CONCAT('".sqlEncode($strNewVolPath)."', substr(FilePath, length('".sqlEncode($strOldVolPath)."')+1)), FileOwner='".$strNewVolName."', updated=1 WHERE id in("
				. join(",", keys %id_list) . ")";
        	$dbConn->Sql($query);

        	$self->{spx}->UpdateAttributes( $self->{indexes}, [ qw/updated/ ], \%id_list );
    	}
    	$dbConn->Close();
}

sub FileUpload {
	my ($self, $strTargetPath, $objUser) = @_;
		
	my $strVolName = $objUser->GetVolumeNameFromPath($strTargetPath);
    	my $strVolPath = $objUser->GetVolumePathFromPath($strTargetPath);
    	my @arrFilePath = split(/\//, $strVolPath);
    	my $strFileName  = $arrFilePath[$#arrFilePath];
	my $strRealPath = $objUser->GetRealPath($strTargetPath);
    	my @arrStat = stat($strRealPath);

	my $MD5Digest = Digest::MD5->new();
	my $strMD5 = $strVolName . $strFileName . $arrStat[9] . ($arrStat[7] eq "") ? "0" : $arrStat[7] ;
	$MD5Digest->add($strMD5);
	my $FileMD5Key = $MD5Digest->b64digest();

	if ($strTargetPath =~ /개인폴더/ ) {
		return;
	}
	my $query = sprintf("INSERT INTO FileList(id, FilePath, FileName, FileSize, FileOwner, CreateTime, FileKey, Adult, updated) VALUES ('', '%s', '%s', %s, '%s', '%s', '%s', 'C', 1)", sqlEncode($strVolPath), sqlEncode($strFileName), ($arrStat[7] eq "") ? "0" : $arrStat[7], $strVolName, $arrStat[9], $FileMD5Key);
	my $dbConn = new eFolder::Database(FileDatabaseAddress);
	$dbConn->Sql($query);
	$dbConn->Close();
}

1;
