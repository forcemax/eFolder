#!/usr/bin/perl
package eFolder::mCGI;
use strict;
use CGI::Util qw(unescape);
use Text::Iconv;
use eFolder::HttpStreamBuffer;

#File데이터가 항상 마지막에 온다고 가정 
#File은 단 하나만 온다고 가정 
#Method 정리 
#New()	: method
	# ENV의 QueryString으로 parameter 변수 생성, ENV로 Connection 정보 변수 생성. 
	# Content-Type:File이거나 입력 stream이 끝날 때까지 stdin을 읽는다. 
	# Post method로 전달된 parameter 변수 만든다. 

#param() : method
 	# hash에서 해당하는 parameter에 대한 값을 전달한다. 
	# 없을 때는 undef를 전달 할 수 있도록 한다. 

#HasHttpFileStream(): method
	#Request가 File uplaod stream을 가지고 있는지 묻는다. 
	#있으면 1 없으면 0을 return한다.

#GetHttpFileStream(): method
	# STDIN으로 입력을 buffering해주는 object에 대한 Handle을 return한다. 
	# File stream이 있을 경우에만 return하고 그 외에는 undef를 return 한다. 

#HttpFileStream : object
	# Content-type: file인 stream에 대한 buffer이다. 
	# 이에 대해서 read를 호출하면 STDIN에서 읽는다. 
	# 화일의 마지막 처리를 정확하게 할 것 
	# {EOF} => EOF이면 1, 아니면 0
	# {RemainLength} : 앞으로 읽어야 하는 데이터의 길이 
	# {DataLength} 	 : 지금까지 읽은 데이터의 길이 
	# {ReadSize} 	 : 한번에 읽을 데이터의 길이 
	# Read(): method 
		# STDIN에서 데이터를 읽어서 return 

sub new {
	my($class) = @_;
	my($self) = ();

	$self->{Error} = '';
	$self->{ContentLength} = $ENV{CONTENT_LENGTH};
	$self->{RemotePort} =$ENV{REMOTE_PORT};
	$self->{RemoteAddress} = $ENV{REMOTE_ADDR};
	$self->{RequestMethod} = $ENV{REQUEST_METHOD};
	$self->{Param} = {};
	$self->{ToKR}  = new Text::Iconv("UTF-8", "EUC-KR");
	$self->{ToUTF8}  = new Text::Iconv("EUC-KR", "UTF-8");
	$self->{Conv}  = $self->{ToKR};
	bless $self, $class;
}

sub param{
	my($self, $param) = @_;

	my $hashParam = $self->{Param};

	if(defined($$hashParam{$param})){
		return $$hashParam{$param};
	}else{
		return undef 
	}
}

sub paramToUTF8{
        my($self, $param) = @_;

        my $hashParam = $self->{Param};

#       print STDERR "$param:<", $$hashParam{$param}, ">\n";

        if(defined($$hashParam{$param})){
                return $self->{ToUTF8}->convert($$hashParam{$param});
        }else{
                return undef
        }
}


sub paramToKR{
        my($self, $param) = @_;

        my $hashParam = $self->{Param};

#       print STDERR "$param:<", $$hashParam{$param}, ">\n";

        if(defined($$hashParam{$param})){
                return $self->{ToKR}->convert($$hashParam{$param});
        }else{
                return undef
        }
}


sub paramIconv{
        my($self, $param) = @_;

        my $hashParam = $self->{Param};

#	print STDERR "$param:<", $$hashParam{$param}, ">\n";

        if(defined($$hashParam{$param})){
		return $self->{Conv}->convert($$hashParam{$param});
        }else{
                return undef
        }
}


sub Parse{
	my($self) = @_;
	#print STDERR " IN PARSE!! \n";
	if(!$self->ParseGETmethod()){
		return 0;
	}
	#print STDERR " AFTER GET \n";
	$self->ParsePOSTmethod();
	#print STDERR " AFTER POST \n";
	return 1;
}


sub HttpHeader{
	my($self) = @_;
	print "Content-Type: text/html\n\n";
}

sub GetRequestHostAddress{
	my($self) = @_;
	return  $self->{RemoteAddress};
}

sub GetRequestHostPort{
	my($self) = @_;
	return $self->{RemotePort};
}

sub GetContentLength{
	my ($self) = @_;
	return $self->{ContentLength};
}

sub GetRequestMethod{
	my($self) = @_;
	return $self->{RequestMethod};
}

sub ParseQueryString{
	my ($self, $strQueryString) = @_;
	#  2007.6.27 jaejunh
	# get rid of \r\n
	$strQueryString =~ s/[\r\n]//g;
	#print STDERR "[mCGI] QUERY STRING: $strQueryString \n";
	my(@pairs) = split(/[&;]/, $strQueryString);
	my $hashParam = $self->{Param};
	my ($strParam, $strValue);

	foreach (@pairs) {
		($strParam, $strValue) = split('=', $_, 2);
		$strValue = '' unless defined $strValue;
		$strParam = unescape($strParam);
		$strValue = unescape($strValue);
		$$hashParam{$strParam} = $strValue;
	}
}

sub ParseGETmethod{
	my($self) = @_;
	if(!defined($ENV{QUERY_STRING})) { return 0; }
	my $strGetRequest = $ENV{QUERY_STRING};
	$self->ParseQueryString($strGetRequest);

	# 2004.12.07 jslee
	my $hashParam = $self->{Param};
	my $strSessionID = $$hashParam{"SessionId"};
	
	if($strSessionID =~ /^U[0-9]+/){ #Shared User 가 아니면 에러.
		return 0;
	}

	return 1;
}


sub ParsePOSTmethod{
	my($self) = @_;
	if($self->{RequestMethod}  ne  "POST") {
		return 0;
	}

	if($ENV{CONTENT_TYPE}=~m|^multipart/form-data|) {
	 	($self->{Boundary}) = $ENV{CONTENT_TYPE} =~ /boundary=\"?([^\";,]+)\"?/;
		$self->{Boundary} = "--".$self->{Boundary};
		$self->ParseFromMultiPartData();
	}else{
		$self->ParseFromSingleData();
	}
}

sub ParseFromSingleData{
	my($self) = @_;
	my $strBuffer;
#TODO:if read가 실패하면 undef를 return한다. 
#이 때 다시 읽어야 할까?
#마지막 CRLF는 잘라주어야 한다. 
	
	#print STDERR "[mCGI] CONTENT LENGTH: $self->{ContentLength} \n";
	my $lBytesRead = read(STDIN, $strBuffer, $self->{ContentLength}, 0);
	if(!defined($lBytesRead)){
		return 0;
	}
	$self->ParseQueryString($strBuffer);
	return 1;
}

sub ParseFromMultiPartData{
	my($self) = @_;

	my $hashParam = $self->{Param};

	print STDERR "[mCGI] ContentLength: $self->{ContentLength} , Boundary : $self->{Boundary} \n";
	my $StreamBuffer = new eFolder::HttpStreamBuffer($self->{ContentLength}, $self->{Boundary});
	return unless $StreamBuffer;
	$self->{StreamBuffer} = $StreamBuffer;

	my(%hashHeader,$strBody); 

	while (!$StreamBuffer->isEOF) {
		%hashHeader = $StreamBuffer->ReadHeader(); 
		unless (%hashHeader) {
			$self->{Error} = "400 Bad request (malformed multipart POST)";
			return;
		} 

		my ($strParam)= $hashHeader{'Content-Disposition'} =~ / name="?([^\";]*)"?/; 
		my ($strFileName) = $hashHeader{'Content-Disposition'} =~ / filename="?([^\"]*)"?/;

	       	if (!defined($strFileName) || $strFileName eq '') {
		       	$$hashParam{$strParam} = unescape($StreamBuffer->ReadBody);
	       	}else{
			$self->{hasHttpFileStream} = 1;
			$self->{StreamFileName} = $strFileName;
			return;
		}
	}
}

sub hasFileStream{
	my($self) = @_;
	if($self->{hasHttpFileStream} == 1){
		return 1;
	}else{
		return 0;
	}
}

sub GetStreamBuffer{
	my ($self) = @_;
	return $self->{StreamBuffer};
}

sub GetUploadFileName{
	my($self) = @_;
	return $self->{StreamFileName};
}

sub printParameterAll{
	my ($self) = @_;
	my %hashParam = %{$self->{Param}};
	foreach my $strKey (keys(%hashParam)){
		print STDERR "$strKey : $hashParam{$strKey} \n";
	}
}

sub printENV{
	foreach my $strKey (keys(%ENV)){
		print " $strKey : $ENV{$strKey} \n";
	}
}
1;
