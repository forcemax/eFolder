use FileHandle;
$fh = new FileHandle "file", "w";
binmode $fh;
$fh->seek(2, 0);
print $fh "aaa";
$fh->close;
