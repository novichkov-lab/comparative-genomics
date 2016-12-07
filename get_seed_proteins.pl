#! /usr/bin/perl
use strict;
use warnings;
use SAPserver;

my $sapServer = SAPserver->new();

################################
###  Download SEED proteins  ###
################################

my $work_dir = "data";
my $proteins_filename = "proteins.txt";

if (@ARGV == 2) {
	$work_dir = $ARGV[0];
	$proteins_filename = $ARGV[1];
} else {
	print "Usage: perl get_seed_proteins.pl <output folder> <output file name>\n";
	exit(0);
};

if (($work_dir ne "")&&(!(-e $work_dir))) {
	print "Directory $work_dir does not exist!\n";
	exit(1);
}

$proteins_filename = $work_dir . "/" . $proteins_filename;

my $genomeHash = $sapServer->all_genomes({
                            -complete => 1,
                            -prokaryotic => 1
                        });

open (OUTFILE, ">$proteins_filename") or die ("Unable to open file $proteins_filename");

#my $limit = 2;

for my $genome_id (keys %$genomeHash) {
#	if ($limit == 0) {last;} else {$limit--;}
	my $fidHash = $sapServer->all_proteins({
							-id => $genome_id
						});
	for my $protein_id (keys %$fidHash) {
		my $sequence = $fidHash->{$protein_id};
		print OUTFILE ">" . $protein_id . "\n ". $sequence. "\n";
	}
}


close OUTFILE;
exit(0);

