#!/usr/bin/perl -w

use strict;
use POSIX;
#use AFS::VOS;
use Digest::MD5;
use Sphinx::Search;
use DBI;

if ($^O eq 'darwin') {
	eval 'use Encode; use Encode::UTF8Mac;';
}

my $CDBCNN = "DBI:mysql:host=127.0.0.1;database=eFolder";
my $CDBCNN_UAS = "DBI:mysql:host=127.0.0.1;database=UAS";
my $CDBUSR = "root";
my $CDBPWD = "embian";

my $hDB = DBI->connect($CDBCNN, $CDBUSR, $CDBPWD);
my $statement = $hDB->prepare("SET NAMES UTF8");
$statement->execute() or die "ERROR\n";
$statement->finish();
$statement = $hDB->prepare("SET CHARACTER SET UTF8");
$statement->execute() or die "ERROR\n";
$statement->finish();

my $NOW = mktime(localtime(time));
my $TIMELOGFILE = "/tmp/lastCrawlRun.time";
my $SPHINXINDEXER = "/opt/sphinx/bin/indexer";
my $SPHINXCONFIGFILE = "/opt/sphinx/etc/sphinx.conf";

sub trim {
	my ($string) = @_;
	$string =~ s/^\s+//g;
	$string =~ s/\s+$//g;
	return $string;
}

sub sqlEncode
{
    my ($sz) = @_;
    $sz =~ s/'/''/g;
    return $sz;
}


#sub getVolumeUpdatedTime {
#	my ( $strUserName ) = @_;

#	my $vos = AFS::VOS->new();
#	my $volinfo = $vos->listvolume("u.".$strUserName);

#	return $volinfo->{updateDate};

#}

sub getLastUpdatedTime {
	open(INFILE, "< $TIMELOGFILE");
	my @lines = <INFILE>;
	my $line = $lines[0];  
	close(INFILE);

	return $line; 
} 

sub setLastUpdatedTime {
  open(OUTFILE, "> $TIMELOGFILE");
	print OUTFILE $NOW;
	close(OUTFILE)
}

sub getAccountList {
	my %AccountList;
	my $strShCommand = "UASClient listAccount";
	open SHHANDLE, "$strShCommand |";
	while (my $line = <SHHANDLE>) {
  	my $templine = trim($line);
		my @linesplit = split(/:/, $templine);	
	  $AccountList{$linesplit[2]} = $linesplit[7];
	}
	close (SHHANDLE);

	return %AccountList;
}

sub getAccountListFromDB {
	my %AccountList = ();

	my $hDB = DBI->connect($CDBCNN_UAS, $CDBUSR, $CDBPWD);
        my ($user,@rest) = @_;
        my $strListAccount="select NAME_COL,HOMEDIR_COL from ACT_TBL where HOMEDIR_COL != ''";
        my $sth = $hDB->prepare($strListAccount);
        $sth->execute() or die "ERROR\n";

        while (my @row = $sth->fetchrow_array()) {
		$AccountList{$row[0]} = $row[1];
        }
        $sth->finish();
	return %AccountList;
}	

sub choiceUpdateList {
	my ( %list ) = @_;

	my %newList;
	foreach my $entry(sort keys %list) {
#		$newList{$entry} = $list{$entry} if ( getLastUpdatedTime() < getVolumeUpdatedTime($entry) );
		$newList{$entry} = $list{$entry};
	}

	return %newList;
}

sub listDirectory {
	my ($strUserName, $strTargetPath, $strPrefix, $depth) = @_;

	my $nResult = opendir hDIR, $strTargetPath;
		
	if ($nResult == 0) {
		print("[ERROR] listDirectory : $strUserName, $strTargetPath : ".$!."\n");
		return;
	}

	my @arrDirectory;

	my $rowCount = 0;
	my $sqlRow = "INSERT INTO FileList(id, FilePath, FileName, FileSize, FileOwner, CreateTime, FileKey, Adult, updated) VALUES ";
	while ( my $strFileName = readdir(hDIR) ) {
		if ($^O eq 'darwin') {
			$strFileName = Encode::decode('utf-8-mac', $strFileName);
		}
		next if ($strFileName eq "." || $strFileName eq ".." || $strFileName eq ".DUP" || $strFileName eq ".DELETED");
		next if ($strFileName eq "개인폴더" && $depth == 0);
		my $strPath = $strTargetPath . "/" . $strFileName;

		if ( -f $strPath ) {
			my @arrStat = stat($strPath);

			$strPath =~ s/$strPrefix//;

			my $MD5Digest = Digest::MD5->new();
			my $strMD5 = $strUserName . $strFileName . $arrStat[9] . ($arrStat[7] eq "") ? "0" : $arrStat[7] ;
			$MD5Digest->add($strMD5);
			my $FileMD5Key = $MD5Digest->b64digest();

			my $strRow = sprintf("('', '%s', '%s', %s, '%s', '%s', '%s', 'C', 1)", sqlEncode($strPath), sqlEncode($strFileName), ($arrStat[7] eq "") ? "0" : $arrStat[7], $strUserName, $arrStat[9], $FileMD5Key);
			$sqlRow .= $strRow.",";
			$rowCount++;
			if($rowCount > 100) {
#				print "[DEBUG] SQL : ". $sqlRow ."\n";				
				$sqlRow =~ s/,$//;
				doQuery($sqlRow);
				$rowCount = 0;
				$sqlRow = "INSERT INTO FileList(id, FilePath, FileName, FileSize, FileOwner, CreateTime, FileKey, Adult, updated) VALUES ";
			} 
		} elsif ( -d $strPath ) {
			push(@arrDirectory, $strPath) if ( ! -l $strPath ); 
		}
	}

#	print STDERR $sqlRow,"\n";

	if ($sqlRow ne "INSERT INTO FileList(id, FilePath, FileName, FileSize, FileOwner, CreateTime, FileKey, Adult, updated) VALUES ") {
#		print "[DEBUG] SQL : ". $sqlRow ."\n";
		$sqlRow =~ s/,$//;
		doQuery($sqlRow);
	}

	closedir(hDIR);

	foreach my $list(@arrDirectory) {
		listDirectory($strUserName, $list, $strPrefix, $depth+1);	
	}

}

sub doQuery {
	my ( $strQuery ) = @_;

	my $sth = $hDB->prepare($strQuery);
	$sth->execute() or die $strQuery."\n";
	$sth->finish();

	return $sth;
}

sub doDeltaIndexing {
	print "doDeltaIndexing\n";
	my $strShCommand = "$SPHINXINDEXER --config $SPHINXCONFIGFILE delta --rotate";
	open SHHANDLE, "$strShCommand |";
	my $strReturn = <SHHANDLE>;
	close (SHHANDLE);
}

sub doCrawling {
	my ( %list ) = @_;

	my $spx = Sphinx::Search->new;
	$spx->SetServer("localhost", 3312);

	foreach my $strUserName(sort keys %list) {
		print "doCrawling : $strUserName\n";
		my $strHome = $list{$strUserName};

#		my $sql;
	#	$sql = "SELECT id FROM FileList WHERE FileOwner = '". $strUserName ."'";
	#	my $sth = $hDB->prepare($sql);
	#	$sth->execute() or die $sql."\n";

	#	while (my @row = $sth->fetchrow_array()) {
	#		$spx->UpdateAttributes( "FileList", [ qw/updated/ ], {$row[0] => [99]} );
	#	}
	
#		$sql = "DELETE FROM FileList WHERE FileOwner = '" . $strUserName ."'";
#		doQuery($sql);

		listDirectory($strUserName, $strHome, $strHome, 0);

	}
}

sub main {
	if ( ! -e $TIMELOGFILE ) {
		open(OUTFILE, "> $TIMELOGFILE");
		print OUTFILE "0";
		close(OUTFILE)
	}

	my %alllist = getAccountListFromDB;
	my %chosenlist = choiceUpdateList(%alllist);

	my $sql = "TRUNCATE FileList";
	doQuery($sql);

	doCrawling(%chosenlist);

	setLastUpdatedTime;

#	doDeltaIndexing;

	exit 0;
}

main;
1;

