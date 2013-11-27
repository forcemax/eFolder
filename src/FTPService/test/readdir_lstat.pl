#!/usr/bin/perl
opendir DIR ,".";

while($name = readdir(DIR)){
	@attribute = lstat($name);
	print $name."=> ";
	print join(' : ', @attribute);
	print "\n";
}

closedir(DIR);


	


