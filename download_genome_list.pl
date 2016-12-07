#! /usr/bin/perl
use 5.010;
use LWP::Simple;
use strict;
use utf8;
use warnings;

##############################################################################
###  Download assembly summary from NCBI and extract complete genome data  ###
##############################################################################
my $work_dir = "data";
my $ftp_url = "ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/bacteria/assembly_summary.txt";
my $genome_list_filename = "genome_list.txt";
if (@ARGV == 2) {
	$work_dir = $ARGV[0];
	$ftp_url = $ARGV[1];
} elsif (@ARGV == 0) {
	# use default settings
	print "Script is running without parameters, default settings will be used: output folder is \"data\", URL is ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/bacteria/assembly_summary.txt\n";
} else {
	print "Usage: perl download_genome_list.pl <output folder> <URL of assembly list>\n";
	print "When run without parameters, default settings are used: output folder is \"data\", URL is ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/bacteria/assembly_summary.txt\n";
	exit(0);
};
if (($work_dir ne "")&&(!(-e $work_dir))) {
	print "Directory $work_dir does not exist!\n";
	exit(1);
}
my @now = localtime();
my $timeStamp = sprintf("%04d%02d%02d%02d%02d%02d", 
                        $now[5]+1900, $now[4]+1, $now[3],
                        $now[2],      $now[1],   $now[0]);
print $timeStamp ;
my $summary_filename = $work_dir."/"."assembly_summary_".$timeStamp.".txt";
my $outfile = $work_dir."/".$summary_filename;my $data = get($ftp_url);
open (OUTFILE, ">$summary_filename") or die ("Unable to write assembly summary file");
binmode(OUTFILE, ":utf8");
print OUTFILE $data."\n";
close OUTFILE;
extract_complete_genomes ($summary_filename, $work_dir."/".$genome_list_filename);exit(0);

#####################
###  SUBROUTINES  ###
#####################

sub extract_complete_genomes {
	my ($assembly_summary, $genome_list) = @_;
	open (INFILE, $assembly_summary) or die ("Unable to read assembly summary from $assembly_summary");
	open (OUTFILE, ">$genome_list") or die ("Unable to create genome list file");
	binmode(OUTFILE, ":utf8");
	my $line;
	while ($line = <INFILE>) {
		chomp $line;
		if ($line =~ /^#/) {
			#skip comments
		} elsif ($line eq "") {
			#skip empty lines
		} else {
			my @entry = split ("\t", $line);
			if ($entry[11] eq "Complete Genome") {
				print OUTFILE $line."\n";
			}
		}
	}
	close OUTFILE;
	close INFILE;
}