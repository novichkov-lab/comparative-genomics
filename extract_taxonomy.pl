#! /usr/bin/perl
use strict;
use utf8;
use warnings;

##############################################################
###  Extract taxonomy information from Genbank flat files  ###
##############################################################

my $work_dir = "data";
my $genome_list_filename = "genome_list.txt";
my $limit = -1;
if (@ARGV == 3) {
	$work_dir = $ARGV[0];
	$genome_list_filename = $ARGV[1];
	$limit = $ARGV[2];
} elsif (@ARGV == 0) {
	# use default settings
	print "Script is running without parameters, default settings will be used: output folder is \"data\", genome list is \"genome_list.txt\", download all genomes\n";
} else {
	print "Usage: perl extract_taxonomy.pl <output folder> <genome list file> <max number of genomes processed>\n";
	print "Default settings are: output folder is \"data\", genome list is \"genome_list.txt\", process all genomes\n";
	exit(0);
};
if (($work_dir ne "")&&(!(-e $work_dir))) {
	print "Directory $work_dir does not exist!\n";
	exit(1);
}

my $taxonomy_filename = $work_dir."/taxonomy.txt";
$genome_list_filename = $work_dir."/".$genome_list_filename;
open (INFILE, $genome_list_filename) or die ("Unable to read genome list from $genome_list_filename");
open (OUTFILE, ">$taxonomy_filename");
binmode(OUTFILE, ":utf8");
my $line;
while ($line = <INFILE>) {
	if ($limit == 0) {
		last;
	};
	$limit--;
	chomp $line;
	my $taxonomy_entry = process_gbffile ($line, $work_dir);
	if ($taxonomy_entry eq "") {
		print "Parsing error for entry $line";
	}
	print OUTFILE $taxonomy_entry;
}
close OUTFILE;
close INFILE;
exit(0);


#####################
###  SUBROUTINES  ###
#####################

sub process_gbffile  {
	my ($line, $work_dir) = @_;
	my $gbff_filename = "_genomic.gbff.gz";
	my $flag = 0;
	my @entry = split ("\t", $line);
	my $ret_value = "";
	my $assembly = $entry[15];
	$assembly =~ s/ /_/g;
	$assembly =~ s/\(/_/g;
	$assembly =~ s/\)/_/g;
	$assembly =~ s/\//_/g;
	$gbff_filename = $work_dir."/".$entry[0]."_".$assembly.$gbff_filename;
	open (GBFFILE, $gbff_filename) or die ("Unable to read gbff file $gbff_filename");
	while ($line = <GBFFILE>) {
		if ($line =~ /^ACCESSION   /) {
			chomp $line;
			$line =~ s/^ACCESSION   //;
			$ret_value .= $entry[0]."\t".$entry[5]."\t".$line;
		} elsif ($line =~ /^  ORGANISM/) {
			chomp $line;
			$line =~ s/  ORGANISM  //g;
			$ret_value .= "\t".$line."\t";
			$flag = 1;
		} elsif ($flag == 1) {
			chomp $line;
			if ($line =~ /^ /) {
				$line =~ s/^            //g;
				$ret_value .= $line." ";
			} else {
				$flag = 0;
			}
		} elsif ($line =~ /^ORIGIN/) {
			$ret_value .= "\n";
		}
	}
	close GBFFILE;
	return $ret_value;
}