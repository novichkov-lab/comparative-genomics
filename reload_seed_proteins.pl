#! /usr/bin/perl
use strict;
use warnings;
use SAPserver;

my $sapServer = SAPserver->new();

################################
###  Download SEED proteins  ###
################################

my $work_dir = "seed";
my $genome_list_filename = "genome_list.txt";
my $processed_genome_list_filename = "processed_genome_list.txt";
my $proteins_filename = "proteins.txt";

if (@ARGV == 2) {
	$work_dir = $ARGV[0];
	$proteins_filename = $ARGV[1];
} else {
	print "Usage: perl reload_seed_proteins.pl <output folder> <output file name>\n";
	exit(0);
};

if (($work_dir ne "")&&(!(-e $work_dir))) {
	print "Directory $work_dir does not exist!\n";
	exit(1);
}

$genome_list_filename = $work_dir . "/genome_list.txt" ;
$processed_genome_list_filename = $work_dir . "/processed_genome_list.txt" ;

my @genomes = ();
my %genomes_processed = ();

open (INFILE, $genome_list_filename) or die ("Genomes list not found");
my $line ="";
while ($line = <INFILE>){
	chomp $line;
	push @genomes, $line;
}
close INFILE;

open (INFILE, $processed_genome_list_filename) or die ("Processed genomes list not found");
while ($line = <INFILE>){
	chomp $line;
	$genomes_processed {$line} = 1;
}
close INFILE;

#my $limit = 2;

for my $genome_id (@genomes) {
#	if ($limit == 0) {last;} else {$limit--;}
	if (exists $genomes_processed {$genome_id}) {
		#do nothing
	} else {
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
		undef ($fidHash);
		open (GENOMEFILE, ">>$processed_genome_list_filename") or die ("Unable to open file $processed_genome_list_filename");
		print GENOMEFILE $genome_id."\n";
		close GENOMEFILE;
	}
}
exit(0);

