#!/usr/bin/perl
package eFolder::CONFIG;
use strict;
use POSIX qw(strftime);
use Exporter();
use eFolder::ReadConfig;

use vars qw(@ISA @EXPORT);
use vars qw(%G_CONFIG);
@ISA =  qw(Exporter);
@EXPORT = qw(
		ReadConfiguration	
		ConfigurationVersion
		PrintConfiguration
		G_DEBUG_RUN
		do_log
		do_debug

		MonitorDatabaseAddress
		UASDatabaseAddress
		FileDatabaseAddress
		ASK_SEARCH_DB
		SessionDatabaseAddress
		ShareDatabaseAddress
		AccountDatabaseAddress
		WebDatabaseAddress
		CONFIGDatabaseAddress
		CDatabaseUserName
		CDatabasePassword 
	        CMountMAX
		DownLoadPassword
		MAX_RESULT_SIZE 
		ClientVersion
		CONST_MIN_COPY_RATE 
		CONST_DUPLICATED_COPY 
		eFolder_MAX_FREE_DAY 
		eFolder_MAX_FREE_TERM 
		eFolder_FREE_TERM
		eFolder_DAY_CHARGE 
		eFolder_DOWN_CHARGE
		eFolder_DOWN_MILEAGE
		eFolder_CLUB_URL
		UAS_TEST_USER
		ADULT_HIT_COUNT
		THIS_SERVER_IS_SUPERC
		S_ADMIN
                S_ADMIN_IP
		SuperClientVersion
		START_FREE_TIME
		END_FREE_TIME
);


#############################################################################################

sub CONFIG_USE_ALTERNATE        {  0;     }
sub CONFIG_DIR                  {  "/opt/eFolder/lib/perl/eFolder"; }
sub CONFIG_FILE                 {  "00.CONFIG"; }
sub CONFIG_FILE_ALTERNATE       {  "11.ALTERNATIVE";  }

sub PrintConfiguration {
	print STDERR "CURRENT CONFIGURATION:\n\n";
	foreach my $i (sort keys %G_CONFIG) {
		my $field = sprintf("%25s", "$i");
		print STDERR sprintf("%s=\t%s\n",$field,$G_CONFIG{$i});
	}
}

########################### DEBUG ################################
sub do_debug {
        my ($content) = @_;
        my $prefix = "DEBUG";
        my $cur_time = strftime("%Y-%m-%d %H:%M:%S", localtime());
	my ($Caller, $FilePath, $Callline, $func) = caller(1);
	my ($package, $filename, $line) = caller;

        if (&G_DEBUG_RUN ne 0) {
                print STDERR sprintf("[%s][%s]%s.%s:%s\n",
					$cur_time, $prefix, 
					$func, $line, 
					$content );
#                print STDERR sprintf("[%s][%s]:\"%s at %s\" called \"%s at %s\":%s\n",
#					$cur_time, $prefix, 
#					$Caller, $Callline, 
#					$func, $line, 
#					$content );
        }
}

########################### LOG  ################################
sub do_log {
        my ($prefix, $content) = @_;
        my $cur_time = strftime("%Y-%m-%d %H:%M:%S", localtime());
#	my ($Caller, $FilePath, $Callline, $func) = caller(1);
        print STDERR sprintf("[%s][%s] %s\n",$cur_time,$prefix,$content);
}

#############################################################################################
# SuperUser

sub S_ADMIN	{  $G_CONFIG{'S_ADMIN'}; }
sub S_ADMIN_IP	{  $G_CONFIG{'S_ADMIN_IP'}; }

sub G_DEBUG_RUN { $G_CONFIG{'G_DEBUG_RUN'}; }
sub ConfigurationVersion	{  $G_CONFIG{'00.CONFIG'}; }
sub UASDatabaseAddress	{  $G_CONFIG{'UASDatabaseAddress'}; }
sub SessionDatabaseAddress	{  $G_CONFIG{'SessionDatabaseAddress'}; }
sub MonitorDatabaseAddress	{  $G_CONFIG{'MonitorDatabaseAddress'}; }
sub ShareDatabaseAddress	{  $G_CONFIG{'ShareDatabaseAddress'}; }
sub FileDatabaseAddress	{  $G_CONFIG{'FileDatabaseAddress'}; }
sub ASK_SEARCH_DB	{  $G_CONFIG{'ASK_SEARCH_DB'}; }
sub TestFileDatabaseAddress	{  $G_CONFIG{'TestFileDatabaseAddress'}; }
sub CONFIGDatabaseAddress       {  $G_CONFIG{'CONFIGDatabaseAddress'}; }
sub AccountDatabaseAddress	{  $G_CONFIG{'AccountDatabaseAddress'}; }
sub WebDatabaseAddress	{  $G_CONFIG{'WebDatabaseAddress'}; }

sub CDatabaseUserName	{  $G_CONFIG{'CDatabaseUserName'}; }
sub CDatabasePassword	{  $G_CONFIG{'CDatabasePassword'}; }
sub DownLoadPassword	{  $G_CONFIG{'DownLoadPassword'}; }

sub CMountMAX	{  $G_CONFIG{'CMountMAX'}; }


sub MAX_RESULT_SIZE	{  $G_CONFIG{'MAX_RESULT_SIZE'}; }

sub ClientVersion	{  $G_CONFIG{'ClientVersion'}; }
sub SuperClientVersion	{  $G_CONFIG{'SuperClientVersion'}; }
sub CONST_MIN_COPY_RATE	{  $G_CONFIG{'CONST_MIN_COPY_RATE'}; }
sub CONST_DUPLICATED_COPY	{  $G_CONFIG{'CONST_DUPLICATED_COPY'}; }

sub eFolder_MAX_FREE_DAY	{  $G_CONFIG{'eFolder_MAX_FREE_DAY'}; }
sub eFolder_MAX_FREE_TERM	{  $G_CONFIG{'eFolder_MAX_FREE_TERM'}; }
sub eFolder_FREE_TERM	{  $G_CONFIG{'eFolder_FREE_TERM'}; }
sub eFolder_DAY_CHARGE	{  $G_CONFIG{'eFolder_DAY_CHARGE'}; }
sub eFolder_DOWN_CHARGE	{  $G_CONFIG{'eFolder_DOWN_CHARGE'}; }
sub eFolder_DOWN_MILEAGE	{  $G_CONFIG{'eFolder_DOWN_MILEAGE'}; }

sub UAS_TEST_USER	{  $G_CONFIG{'UAS_TEST_USER'}; }
sub ADULT_HIT_COUNT	{  $G_CONFIG{'ADULT_HIT_COUNT'}; }
sub THIS_SERVER_IS_SUPERC	{  $G_CONFIG{'THIS_SERVER_IS_SUPERC'}; }

sub START_FREE_TIME { $G_CONFIG{'START_FREE_TIME'}; }
sub END_FREE_TIME   { $G_CONFIG{'END_FREE_TIME'}; }

sub main {
	if(!defined(ConfigurationVersion)){
		%G_CONFIG = eFolder::ReadConfig::ReadConfiguration('/opt/eFolder/etc/00.CONFIG');
	}
#	print STDERR "[JSLEE]" . FileServerURL . "\n";

}

main;
1;
