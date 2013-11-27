#!/usr/bin/perl -w
package SOAP::Transport::HTTP::Apache_EUCKR;

# Following perl package is made from SOAP::Lite(0.69)'s SOAP/Transport/HTTP.pm
# ToDo:   I need to study perl's sub-classing.
#         Next time, try sub-classing "SOAP::Transport::HTTP::Apache"
#         Here, do sub-classing "SOAP::Transport::HTTP::Server" 

use strict;

use vars qw(@ISA);
use SOAP::Transport::HTTP;

@ISA = qw(SOAP::Transport::HTTP::Server);

sub DESTROY { SOAP::Trace::objects('()') }

sub new {
  my $self = shift;
  unless (ref $self) {
    my $class = ref($self) || $self;
    $self = $class->SUPER::new(@_);
    SOAP::Trace::objects('()');
  }
 MOD_PERL: {
	if( $mod_perl::VERSION < 1.99  ){
        require Apache;
        require Apache::Constants;
        Apache::Constants->import('OK');
        $self->{'MOD_PERL_VERSION'} = 1;
        $self->{OK} = &Apache::Constants::OK;
        last MOD_PERL;
    }elsif( $mod_perl::VERSION >= 1.99 && $mod_perl::VERSION < 2.0) {

        require Apache::RequestRec;
        require Apache::RequestIO;
        require Apache::Const;
        Apache::Const->import(-compile => 'OK');
        $self->{'MOD_PERL_VERSION'} = 2;
        $self->{OK} = &Apache::OK;
        last MOD_PERL;
    }else {
      require Apache2::RequestRec;
      require Apache2::RequestUtil;
      require Apache2::RequestIO;
      require Apache2::Const;
      require APR::Table;
      Apache2::Const->import(-compile => 'OK');
      $self->{'MOD_PERL_VERSION'} = 2;
      last MOD_PERL;
    }

    (eval { require Apache;} ) and do {
       require Apache::Constants;
       Apache::Constants->import('OK');
       $self->{'MOD_PERL_VERSION'} = 1;
       last MOD_PERL;
     };
    die "Unsupported version of mod_perl by jslee";
  }
  return $self;
}


sub handler { 
  my $self = shift->new; 
  my $r = shift;

  # Begin patch from JT Justman
  if (!$r) {
      if ( $self->{'MOD_PERL_VERSION'} < 2 ) { 
	  $r = Apache->request();
      } else { 
	  $r = Apache2::RequestUtil->request();
      }
  }
  
  my $cont_len;
  if ( $self->{'MOD_PERL_VERSION'} == 1 ) { 
      $cont_len = $r->header_in ('Content-length');
  } else { 
      $cont_len = $r->headers_in->get('Content-length'); 
  }
  if ($r->headers_in->{'Expect'} =~ /\b100-Continue\b/i) {
      $r->print("HTTP/1.1 100 Continue\r\n\r\n");
  }
  # End patch from JT Justman

  $self->request(HTTP::Request->new( 
    $r->method() => $r->uri,
    HTTP::Headers->new($r->headers_in),
    do { 
	my ($c,$buf); 
	while ($r->read($buf,$cont_len)) { 
	    $c.=$buf; 
	} 
	$c; 
    }
  ));
  #$self->SUPER::handle;
  $self->SOAP::Transport::HTTP::Server::handle;

  # we will specify status manually for Apache, because
  # if we do it as it has to be done, returning SERVER_ERROR,
  # Apache will modify our content_type to 'text/html; ....'
  # which is not what we want.
  # will emulate normal response, but with custom status code 
  # which could also be 500.
  $r->status($self->response->code);

  # Begin JT Justman patch

  # Embian Patch
    my $content = $self->response->content;
    my $buf = "";
    open (MEM, ">", \$buf);
    print MEM $content;
    close(MEM);

    $content = pack "U0C*", unpack "C*", $buf;
    $buf = pack "C*", unpack "U0C*", $content;
    my $new_len = length($buf);

  if ( $self->{'MOD_PERL_VERSION'} > 1 ) {
      $self->response->headers->scan(sub { my %h = @_;
					for (keys %h) {
						if ($_ =~ /^Content-Length/i) {
							$r->headers_out->{$_} = $new_len;
						} else {
							$r->headers_out->{$_} = $h{$_};
						}
					}
					});
      $r->content_type(join '; ', $self->response->content_type);
  } else {
      $self->response->headers->scan(sub { $r->header_out(@_) });
      $r->send_http_header(join '; ', $self->response->content_type);
  }
  #$r->print($self->response->content);
  $r->print($buf);
  return $self->{OK};
  # End JT Justman patch

}

sub configure {
  my $self = shift->new;
  my $config = shift->dir_config;
  foreach (%$config) {
    $config->{$_} =~ /=>/
      ? $self->$_({split /\s*(?:=>|,)\s*/, $config->{$_}})
      : ref $self->$_() ? () # hm, nothing can be done here
                        : $self->$_(split /\s+|\s*,\s*/, $config->{$_})
      if $self->can($_);
  }
  $self;
}



{ sub handle; *handle = \&handler } # just create alias

1;

#


package HandlerEUCKR;
use strict;

use SOAP::Transport::HTTP;

my $server = SOAP::Transport::HTTP::Apache_EUCKR
				 -> serializer(Service2::Serializer->new)
				 -> dispatch_to(@INC); 

sub handler{ $server->handler(@_) ; }

BEGIN {
	package Service2::Serializer;
	@Service2::Serializer::ISA = 'SOAP::Serializer';
	sub as_string {
		my $self = shift;
		my($value, $name, $type, $attr) = @_;
#		print STDERR "[JSLEE HANDLER] $value \n";
		require MIME::Base64;
		$value =~ s/^xsd\:string//;
		return [$name, {'xsi:type' => 'xsd:base64Binary', %$attr}, MIME::Base64::encode_base64($value,'')];
	}
	
	sub as_base64Binary {
		my $self = shift;
		my($value, $name, $type, $attr) = @_;
		my $conv = new Text::Iconv("UTF8","cp949");
		$value = $conv->convert($value);
#		print STDERR "[JSLEE HANDLER BASE64] $value \n";
		require MIME::Base64;
		$value =~ s/^xsd\:string//;
		return [$name, {'xsi:type' => 'xsd:base64Binary', %$attr}, MIME::Base64::encode_base64($value,'')];
	}
	## libsoap-lite-perl 0.69 : date Type Add
	sub as_base64; *as_base64 = \&as_base64Binary;
	sub as_date; *as_date = \&as_string;
	sub as_dateTime; *as_dateTime = \&as_string;
}

1;
