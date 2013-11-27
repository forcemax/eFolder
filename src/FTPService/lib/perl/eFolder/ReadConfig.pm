#!/usr/bin/perl
package eFolder::ReadConfig;
use strict;
use POSIX qw(strftime);

#############################################################################################

sub ReadConfiguration {                  
		my ($config_file) = @_;
		my %CONFIG = ();
        #my $config_file = &CONFIG_DIR . "/" .  (&CONFIG_USE_ALTERNATE ? &CONFIG_FILE_ALTERNATE : &CONFIG_FILE);
		#print STDERR "[JSLOG] ReadConfiguration !!! \n";
        if (!open(INFILE, "< $config_file")) {
                print STDERR "CONFIG::Init Error:  Cannot Open '$config_file'\n";
                print STDERR "CONFIG::Init Error:  using backup '$config_file.bak'\n";
                if (! open(INFILE, "< $config_file.bak")) {
                        print STDERR "CONFIG::Init Error:  Fatal Error.  Cannot open  '$config_file.bak'\n";
                         return 0;
                }
        }
        while (my $line = <INFILE>) {
			# delete blank 
			$line =~ s/^[ \t\n\r]*//g;
			$line =~ s/[ \t\n\r]*$//g;
			
			if ($line =~ /^#/) {
				# comment. skip
				next;
			}
			my @arg = split(/\=/, $line);
			if ($#arg < 1) {
				# this is not config. skip
				next;
			}
			if ($arg[0] eq "S_ADMIN_IP"){
				$CONFIG{$arg[0]} = $arg[1];
				next;
			}
			if ($arg[1] =~ /^[\-\+\/\*0-9\.]+$/) {
				# number computation.  do calculate
				my $ret = eval '$arg[1]=' . $arg[1] . ";";
			}
			if ($arg[0] eq "00.CONFIG") {
				$arg[1] .= ", " . $config_file;
			}

			$CONFIG{$arg[0]} = $arg[1];
			#print STDERR "[DEBUG]: G_CONFIG{'$arg[0]'}=$G_CONFIG{$arg[0]}\n";
        }
        close(INFILE);

        return %CONFIG;
}

1;
