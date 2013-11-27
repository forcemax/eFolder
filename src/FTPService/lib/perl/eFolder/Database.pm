#!/usr/bin/perl -w
BEGIN{ use lib qw(/opt/eFolder/lib/perl)};
package eFolder::Database;
use strict;
use DBI;
use eFolder::CONFIG; 

sub new
{
	my($class, $DSN) = @_;
	my $self = {};
	$self->{debug} = 0;
	$self->{err} = 0;
	$self->{err_str} = "";
	$self->{numrows} = 0;
	if( G_DEBUG_RUN ne 0 ){
		my ( $caller ) = caller(1); 
	} 
	$self->{dbh} = DBI->connect($DSN,CDatabaseUserName, CDatabasePassword) || return 0;
	$self->{sql} = "";
	bless $self, $class;
}

sub Debug {
	my($self, $debug) = @_;
	$self->{debug} = $debug;
}

sub Sql
{
	my($self, $sql) = @_;
	my $buffer = $sql;

	if( !$self->{dbh}){
		do_debug("Connect error : $buffer");
		return 0;
	}

	if( $] >= 5.008 ) {
		open (MEM , '>', \$buffer) ;
		print MEM $sql;
		close MEM;
	} 

	$self->{sth} = $self->{dbh}->prepare("SET NAMES UTF8");
	$self->{sth}->execute;
	$self->{sth} = $self->{dbh}->prepare("SET CHARACTER SET UTF8");
	$self->{sth}->execute;

	$self->{sql} = $buffer;
	$self->{sth} = $self->{dbh}->prepare($buffer);

	if(!($self->{sth})){
		$self->{err} = 1;
		$self->{err_str} = $self->{sth}->{err_str};
		$self->{numrows} = 0;
		do_debug("SQL prepare error : $buffer");
		return 0;
	}
	
	do_debug("SQL execute : $buffer");

	$self->{sth}->execute;

	if($self->{sth}->err){
		$self->{err} = 1;
		$self->{err_str} = $self->{sth}->errstr;
		do_debug("SQL execute error : $buffer");
		return 0;
	}else{
		$self->{err} = 0;
	}

	$self->{numrows}= $self->{sth}->rows;
	return 1;
}

sub Quote {
	my $self    = shift;
	my $str     = shift;
	if ($] < 5.008) {
		return $self->Quote_5_6($str);
	}
    
	return $self->Quote_5_8($str);
}



sub Quote_5_8 {
	my $self    = shift;
	my $str     = shift;

	# magic code to solve encoding problem
	# Remember! If str is null, use default.
	if ($str) {
		my $buffer="";
        	open(MEM, '>', \$buffer);
        	print MEM $str;
        	close MEM;
        	$str = $buffer;
    	}
    	return $self->{dbh}->quote($str);
}


sub Quote_5_6 {

    	my $self    = shift;
    	my $str     = shift;

    	my $buffer="''";
    	if ($str) {
        	$str =~ s/\'/\\'/g;
        	$buffer = sprintf("'%s'", $str);
    	}
    	return $buffer;
}



sub IsError{
	my($self) = @_;
	return $self->{err};
}

sub getErrMsg{
	my($self) = @_;
	return $self->{err_str};
}

sub getNumRows{
	my ($self) = @_;
	return $self->{numrows} ;
}

sub Close
{
	my($self) = @_;
    	$self->{sth}->finish if ($self->{sth});
    	$self->{dbh}->disconnect if ($self->{dbh});
}

sub FetchRow
{
   	my($self) = @_;
   
   	$self->{row} = $self->{sth}->fetchrow_hashref();

   	return $self->{row};
}


sub Data
{
    	my($self, $field) = @_;
    	return 0 if (!$self->{row}->{$field}); 

	$self->{row}->{$field} =~ s/\s+$//;

    	return $self->{row}->{$field}; 
}


sub Binary
{
	my($self, $field) = @_;
	return 0 if (!$self->{row}->{$field});

    	return $self->{row}->{$field};
}


sub GetColumnName
{
        my($self, $num) = @_;
        if( $num >= $self->{sth}->{NUM_OF_FIELDS} ){
                return 0;
        }

        return $self->{sth}->{NAME}->[$num];
}

sub GetColumnType
{
        my($self, $num) = @_;
	my @type_info=(
		"UNKNOWN",      #SQL_ALL_TYPES  0
		"CHAR",         #SQL_CHAR       1       
		"INT",          #SQL_NUMERIC    2 
		"INT",          #SQL_DECIMAL    3
		"INT",          #SQL_INTEGER    4       
		"INT",          #SQL_SMALLINT   5
		"FLOAT",        #SQL_FLOAT      6
		"FLOAT",        #SQL_REAL       7
		"DOUBLE",       #SQL_DOUBLE     8
		"DATE",         #SQL_DATE       9
		"VARCHAR",      #SQL_TIME       10
		"VARCHAR",      #SQL_TIMESTAMP  11
		"VARCHAR",      #SQL_VARCHAR    12
	);

        if( $num >= $self->{sth}->{NUM_OF_FIELDS} ){
                return 0;
        }
        my $type = $self->{sth}->{TYPE}->[$num];

        return $type_info[$type];
}

sub GetColumnLength
{
        my($self, $num) = @_;
        if( $num >= $self->{sth}->{NUM_OF_FIELDS} ){
                return 0;
        }
        return $self->{sth}->{PRECISION}->[$num];
}

sub GetNumOfFields
{
        my($self, $num) = @_;
        return $self->{sth}->{NUM_OF_FIELDS} ;
}

1;

