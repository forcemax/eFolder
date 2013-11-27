#!/usr/bin/perl

package eFolder::HttpStreamBuffer;
use strict;

use Apache2::RequestIO;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::Connection;

use APR::Socket;
use APR::Const -compile => qw(SO_NONBLOCK TIMEUP POLLIN SUCCESS );

use vars qw($SPIN_LOCK_MAX $BUFFER_LENGTH);
#define Constant
$SPIN_LOCK_MAX = 200;
$BUFFER_LENGTH = 1024*4;
sub new {
	my($class, $lDataLength, $strBoundary) = @_;
	my ($self) = ();
	$self->{BytesToRead} = $lDataLength;
	$self->{Boundary} = $strBoundary;
	$self->{BufferLength} = 0;
	$self->{Buffer} = '';
	$self->{ZERO_LOOP_COUNTER} = 0;
	$self->{BoundaryCount} = 0;
	bless $self, $class;
}

sub isEOF{
	my($self) = @_;
	if($self->{BytesToRead} == 0 && length($self->{Buffer}) == 0){
		return 1;
	}else{
		return 0;
	}
}

sub ReadHeader{
	my($self) = @_;
	my $CRLF = "\r\n";
	my $nHeaderEndPos;
	my ($ok, $bad) = (0,0);

	do{
		#버퍼 길이만큼 읽기 시도 
		if( !defined( $self->ReadFromBuffer($BUFFER_LENGTH) ) ){
			print STDERR "read error \n";
			#읽기가 실패하면 
			return ();
		}
	
		#Section의 끝을 찾아보고 
		$nHeaderEndPos = index($self->{Buffer}, "${CRLF}${CRLF}") ;
		
		#버퍼에서 HTTP Section의 끝(\r\n\r\n)이 발견되면 나간다. 
		#Read에 실패하면 {Buffer}는 ''가 되면서 loop를 나간다.
		if($self->{Buffer} eq '' || $nHeaderEndPos >= 0){
			$ok = 1;
		}
		
		#Content-Length만큼 읽었음에도 Header의 끝이 없으면 Error 
		if(!$ok && $self->{BytesToRead} <= 0){
			$bad = 1;
		}
		# HTTP Header의 끝이 아직 오지 않았고, 읽을 데이터가 남아 있을 때까지 읽는다. 
	} until $ok || $bad;
	
	if($bad || $self->{Buffer} eq '') {
		return ();
	}
	
	#Section Data를 Buffer로 부터 분리한다.
	my $strHeader = substr($self->{Buffer}, 0, $nHeaderEndPos + 2);
	substr($self->{Buffer}, 0, $nHeaderEndPos+4) = '';
	
	#Section의 Data로 parameter Hash를 만든다. 
	my %hashReturn;
	my $strToken = '[-\w!\#$%&\'*+.^_\`|{}~]';
	$strHeader =~ s/$CRLF\s+/ /og;
	
	while($strHeader=~/($strToken+):\s+([^$CRLF]*)/mgox){
		my ($strFieldName, $strFieldValue) = ($1, $2);
		$strFieldName =~ s/\b(\w)/uc($1)/eg;
		$hashReturn{$strFieldName} = $strFieldValue;
	}
	return %hashReturn;
}


sub ReadBody{
	my($self) = @_;
	my $strData;
	my $strBody ='';
	while (defined($strData = $self->ReadStream())) {
		$strBody .= $strData;
	}
	return $strBody;
}

sub ReadFromBuffer{
	my ($self, $lBytes) = @_;

	my $lBoundaryLength = length($self->{Boundary});
	my $lBufferOffset = length($self->{Buffer});

	if($lBufferOffset > $lBoundaryLength + 1) {
		return $lBufferOffset - $lBoundaryLength - 1;
	}

	return unless $self->{BytesToRead};
	#읽어야할 데이터는 요청한 데이터 +  Boudary다...
	#요청할 때는 boundary의 사이즈를 빼고 생각한다.  
	my $lBytesToRead = $lBytes - $lBufferOffset + $lBoundaryLength + 2;
	
	$lBytesToRead = $self->{BytesToRead} if $self->{BytesToRead} < $lBytesToRead;
	
	# Try to read some data.  We may hang here if the browser is screwed up.  
	my $lBytesRead = 0; 
	binmode STDIN;

	my $r = Apache2::RequestUtil->request;
#	print STDERR "[JSLEE] lBytesToRead: $lBytesToRead lBufferOffset: $lBufferOffset\n";
	$lBytesRead = eval { $r->read($self->{Buffer} , $lBytesToRead, $lBufferOffset) };
#	print STDERR "[JSLEE] Read Length: $lBytesRead \n"; 
	if( $@ && ref $@ eq 'APR::Error') {
		print STDERR "[HttpStreamBuffer.pm][ReadFromBuffer]Upload stoped : closed\n";
		$self->{Buffer} = '';
		$self->{BytesToRead} = 0;
		return undef;
	}

	if(!defined($self->{Buffer})){
		print STDERR "[HttpStreamBuffer.pm][ReadFromBuffer]Upload stoped : undefined error\n";
		$self->{Buffer} = '';
		$self->{BytesToRead} = 0;
		return undef;
	} 
	
	# An apparent bug in the Apache server causes the read()
	# to return zero bytes repeatedly without blocking if the
	# remote user aborts during a file transfer.  I don't know how
	# they manage this, but the workaround is to abort if we get
	# more than SPIN_LOOP_MAX consecutive zero reads.
	if ($lBytesRead == 0) {
		#EOF를 -1이라고 해서 return한다. 
		if ($self->{ZERO_LOOP_COUNTER}++ >= $SPIN_LOCK_MAX) {
			$self->{Buffer} = '';
			$self->{BytesToRead} = 0;
			return undef;
		}
	} else {
		$self->{ZERO_LOOP_COUNTER} = 0;
	}
	
	$self->{BytesToRead} -= $lBytesRead;
	return $lBytesRead;
}

sub mysubstr {
	my($self, $what,$where,$howmuch) = @_;
	if ($howmuch < 0) {
		my $len = length($what);
		if ($howmuch < 0) {
			$howmuch += $len;
		}
	}
	unpack("x$where a$howmuch", $what);
}


sub ReadStream{
	my ($self,$lBytes) = @_;
	my ($lBytesToReturn, $lReceivedBytes) = ();

	$lBytes = $lBytes || $BUFFER_LENGTH;
	$lReceivedBytes = $self->ReadFromBuffer($lBytes);
	if(!defined($lReceivedBytes)){
		return undef;
	}

	#Boundary를 찾는다. 
	my $nBoundaryPos = index($self->{Buffer},$self->{Boundary});

	if ($nBoundaryPos >= 0) {
		$self->{BoundaryCount} += 1;
	}
	
	#print STDERR "[JSLEE] Boundary Count: ". $self->{BoundaryCount} . "\n";
	#Data Section의 끝이 새로 읽은 데이터의 시작이면 undef를 return
	if ($nBoundaryPos == 0) {
		#Multipart Data의 마지막 DataSection이면        
		if (index($self->{Buffer},"$self->{Boundary}--") == 0) {
			#print STDERR "[JSLEE UPLOAD] Final Data Section [". $self->{Buffer} . "\n\n";
			$self->{Buffer}='';
			$self->{BytesToRead}=0;
			return undef;
		}
		#Boudary와 CRLF를 Buffer에서 제거해서 한 후 undef를 Return 
		#print STDERR "[JSLEE UPLOAD] Error Section [". $self->{Buffer} . "\n\n";
		substr($self->{Buffer},0,length($self->{Boundary}) + 2)='';
		$self->{Buffer} =~ s/^\012\015?//;
		return undef;
	}
	
	
	if ($nBoundaryPos > 0){
		#$lBytesToReturn = $nBoundaryPos > $lBytes ? $lBytes : $nBoundaryPos;
		$lBytesToReturn = $nBoundaryPos;
	} else {
		#Boudnary가 존재하지 않으면 Buffer의 끝까지 읽어서 Return한다. 
		#다만 현재 Buffer에 Boundary의 일부 데이터가 있을 수 있으므로 
		#현재 Buffer에서 Boundary만큼의 데이터는 이후의 processing을 위해 남겨둔다. 
		#$lBytesToReturn = $lBytes - (length($self->{Boundary}) + 1);
		$lBytesToReturn = length($self->{Buffer}) - (length($self->{Boundary}) + 1);
	}
	
	#Buffer에서 반환할 데이터를 꺼내고 Buffer의 크기를 줄인다. 
	my $strData =substr($self->{Buffer},0,$lBytesToReturn);
	substr($self->{Buffer},0,$lBytesToReturn)='';
	
	#만약 boundary까지 읽은 경우에는 마지막 CRLF를 제거한다. 
	return ($nBoundaryPos > 0) ? substr($strData,0,-2) : $strData;
}

1;
