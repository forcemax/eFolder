my @arr = stat("/afs/embian.gnu/home/hjpark/hjpark");
print join("\n", @arr);
my @gg = gmtime($arr[8]);
print "------------\n";
print "value:".$arr[8]."\n";
print join("\n", @gg);

