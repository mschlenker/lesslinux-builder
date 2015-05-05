#! c:\perl\bin\perl.exe
#-----------------------------------------------------------
# This is a simple script to demonstrate the use of the JumpList.pm
# module.
#
# Author: H. Carvey, keydet89@yahoo.com
# copyright 2011-2012 Quantum Research Analytics, LLC
#-----------------------------------------------------------
use strict;
use JumpList;
my @files;

# You can run this code by passing the path to a directory containing
# Jump List files, or a single *.automaticDestinations-ms Jump List file
my $file = shift || die "You must enter a file or directory name.\n";
die $file." not found.\n" unless (-e $file);

if (-d $file) {
	$file .= "\\" unless ($file =~ m/\\$/);
	opendir(DIR,$file);
	while (my $f = readdir(DIR)) {
		next unless ($f =~ m/\.automaticDestinations-ms$/);
		push(@files,$file.$f);
	}
	close(DIR);
}

push(@files,$file) if (-f $file);

my %hash;
foreach (@files) {
	print "\n";
	print $_."\n";
	my $jl = JumpList->new($_);
	my %dl = $jl->getDestList();
	
	my %dir = $jl->getDirectoryTable();
	delete $dir{"DestList"};
	
	foreach my $k (keys %dl) {
		my $t = $dl{$k}{position};
		my $mru = $dl{$k}{mrutime};
#		my $str = $jl->getStream($k);
#		next if (length($str) < 0x4C);
		push(@{$hash{$mru}},$dl{$k}{str});
	}
	
	foreach my $t (reverse sort {$a <=> $b} keys %hash) {
		print gmtime($t)."\n";
		foreach my $i (@{$hash{$t}}) {
			print "  ".$i."\n";
		}
	}
}     