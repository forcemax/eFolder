package temp;

sub new{
	my($class) = @_;
	my($self) = ();
		$self->{temp} = "hi";
	bless $self, $class;
}

sub hashMe{
	my($self) = @_;
	my %hashTemp;
	$hashTemp{hi} = 0;
	$hashTemp{low} = 1;
	$self->{hash} = \%hashTemp;
}

sub printHash{
	my($self) = @_;
#copy hash 
	my %hashYou = %{$self->{hash}};
	print $hashYou{hi}, "\n";
	print $hashYou{low}, "\n";
	$hashYou{hi} = "hjpark";
	$self->{hash} = \%hashYou;
}

sub printPointer{
	my($self) = @_;
	my $hashYou = $self->{hash};
	print $$hashYou{hi}, "\n";
	print $$hashYou{low}, "\n";
	$$hashYou{hi} = "hjpark";
}

$objTemp = new temp;
$objTemp->hashMe;
#$objTemp->printHash;
$objTemp->printPointer;
#$objTemp->printHash;
$objTemp->printPointer;
