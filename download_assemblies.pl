#! /usr/bin/perl
use 5.010;
use LWP::Simple;
use strict;
use utf8;
use warnings;

##############################################
###  Download genome assemblies from NCBI  ###
##############################################
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
	print "Usage: perl download_assemblies.pl <output folder> <genome list file> <max number of genomes downloaded>\n";
	print "Default settings are: output folder is \"data\", genome list is \"genome_list.txt\", download all genomes\n";
	exit(0);
};
if (($work_dir ne "")&&(!(-e $work_dir))) {
	print "Directory $work_dir does not exist!\n";
	exit(1);
}

$genome_list_filename = $work_dir."/".$genome_list_filename;
open (INFILE, $genome_list_filename) or die ("Unable to read genome list from $genome_list_filename");
my $line;
while ($line = <INFILE>) {
	if ($limit == 0) {
		last;
	};
	$limit--;
	chomp $line;
	download_genome ($line, $work_dir);	
}
close INFILE;exit(0);

#####################
###  SUBROUTINES  ###
#####################
sub download_genome  {
	my ($line, $work_dir) = @_;
	#my $feature_table_filename = "_feature_table.txt.gz";
	#my $feature_table_filename = "_cds_from_genomic.fna.gz";
	my $gbff_filename = "_genomic.gbff.gz";
	my $gff_filename = "_genomic.gff.gz";
	my $protein_filename = "_protein.faa.gz";
	my @entry = split ("\t", $line);
	my $assembly = $entry[15];
	$assembly =~ s/ /_/g;
	$assembly =~ s/\(/_/g;
	$assembly =~ s/\)/_/g;
	$assembly =~ s/\//_/g;
	my $ftp_url = $entry[19]."/".$entry[0]."_".$assembly.$gbff_filename;
	print "Downloading $ftp_url...  ";
	my $data = get($ftp_url);
	$gbff_filename = $work_dir."/".$entry[0]."_".$assembly.$gbff_filename;
	open (OUTFILE, ">$gbff_filename");
	binmode(OUTFILE, ":utf8");
	print OUTFILE $data."\n";
	close OUTFILE;
	print "Done.\n";

	$ftp_url = $entry[19]."/".$entry[0]."_".$assembly.$gff_filename;
	print "Downloading $ftp_url...  ";
	$data = get($ftp_url);
	$gff_filename = $work_dir."/".$entry[0]."_".$assembly.$gff_filename;
	open (OUTFILE, ">$gff_filename");
	binmode(OUTFILE, ":utf8");
	print OUTFILE $data."\n";
	close OUTFILE;
	print "Done.\n";	$ftp_url = $entry[19]."/".$entry[0]."_".$assembly.$protein_filename;
	print "Downloading $ftp_url...  ";
	$data = get($ftp_url);
	$protein_filename = $work_dir."/".$entry[0]."_".$assembly.$protein_filename;
	open (OUTFILE, ">$protein_filename");
	binmode(OUTFILE, ":utf8");
	print OUTFILE $data."\n";
	close OUTFILE;
	print "Done.\n";

}