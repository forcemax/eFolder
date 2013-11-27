$ENV = "content-type: boundary=--------akdjlajfa;";
my ($Boundary) = $ENV =~ /boundary=\"?([^\";,]+)\"?/;

print $Boundary;

