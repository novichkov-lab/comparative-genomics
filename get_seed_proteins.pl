#! /usr/bin/perl
use strict;
use warnings;
use SAPserver;

my $sapServer = SAPserver->new();

################################
###  Download SEED proteins  ###
################################

my $work_dir = "seed";
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


my $genomeHash = $sapServer->all_genomes({
                            -complete => 1,
                            -prokaryotic => 1
                        });


#my $limit = 2;

my $genome_list_file = $work_dir . "/genome_list.txt" ;
open (OUTFILE, ">$genome_list_file") or die ("Unable to open file $genome_list_file");
print OUTFILE join ("\n", keys %$genomeHash);
close OUTFILE;

$genome_list_file = $work_dir . "/processed_genome_list.txt" ;

for my $genome_id (keys %$genomeHash) {
#	if ($limit == 0) {last;} else {$limit--;}
	my $fidHash = $sapServer->all_proteins({
							-id => $genome_id
						});
	
	my $out_filename = $work_dir . "/" . $genome_id ."_". $proteins_filename;
	open (OUTFILE, ">$out_filename") or die ("Unable to open file $out_filename");

	for my $protein_id (keys %$fidHash) {
		my $sequence = $fidHash->{$protein_id};
		print OUTFILE ">" . $protein_id . "\n ". $sequence. "\n";
	}
	close OUTFILE;
	open (GENOMEFILE, ">>$genome_list_file") or die ("Unable to open file $genome_list_file");
	print GENOMEFILE $genome_id."\n";
	close GENOMEFILE;

}
exit(0);

