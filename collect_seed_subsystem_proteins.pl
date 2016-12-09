#! /usr/bin/perl
use strict;
use warnings;
use SAPserver;

my $sapServer = SAPserver->new();

######################################
###  Download all SEED subsystems  ###
######################################

my $proteome_dir = "seed";
my $subsystem_dir = "seed_subsystems";
my $limit = -1;
my $subsystems_file = "subsystems_list.txt";
my $roles_file = "roles_list.txt";
my $subsystem_file_prefix = "_subsystem.txt";
my $proteome_file_prefix = "_proteins.txt";
my @subsystems =();
my %genes = ();
my %proteins_written = ();
my %genomes_not_found = ();

if (@ARGV == 3) {
	$proteome_dir = $ARGV[0];
	$subsystem_dir = $ARGV[1];
	$limit = $ARGV[2];
} elsif (@ARGV == 2) {
	$proteome_dir = $ARGV[0];
	$subsystem_dir = $ARGV[1];
} else {
	print "Usage: perl collect_seed_subsystem_proteins.pl <folder with protein files> <folder with subsystem files> <number of subsystems to process (optional)>\n";
	print "This program requires files with SEED proteomes downloaded by get_seed_proteins.pl and SEED subsystems downloaded by get_seed_subsystems.pl\n";
	exit(0);
};

if (($proteome_dir ne "")&&(!(-e $proteome_dir))) {
	print "Directory $proteome_dir does not exist!\n";
	exit(1);
}

if (($subsystem_dir ne "")&&(!(-e $subsystem_dir))) {
	print "Directory $subsystem_dir does not exist!\n";
	exit(1);
}

#Read list of subsystems
$subsystems_file = $subsystem_dir . "/" . $subsystems_file;
open (SUBSFILE, $subsystems_file) or die ("Unable to open file $subsystems_file");
my $line ="";
while ($line = <SUBSFILE>){
	chomp $line;
	push @subsystems, $line;
}
close SUBSFILE;

for my $subsystems_entry (@subsystems) {

	my ($subsystem_id, $subsystem_name) = split ("\t", $subsystems_entry);
	my $outfile = $subsystem_dir . "/" . $subsystem_id . $proteome_file_prefix;
	if (-e $outfile) {
		print "File $outfile exists, subsystem \" \" skipped ";
	} else {
	
		#stop processing if limit reached
		if ($limit == 0) {
			last;
		} else {
			$limit-- ;
		}
		#find file with gene identifiers
		my $subsystem_file = $subsystem_dir . "/" . $subsystem_id . $subsystem_file_prefix;
		open (SUBSFILE, $subsystem_file) or die ("Subsystem file $subsystem_file not found");
		
		open (OUTFILE, ">$outfile") or die ("Unable to open file $outfile ");
		#process gene identifiers, find protein sequences
		my $current_genome = "";
		while ($line = <SUBSFILE>) {
			chomp $line;
			if ($line eq "") {
				$current_genome = ""; #empty line in subsystems file was inserted between different genomes
			} else {
				my ($subsystem_id, $role_id, $gene_id) = split ("\t", $line);
				
				my $genome_id = get_genome_id ($gene_id);
				#if we go to new genome, clean up list of proteins, open next proteome file and load protein sequences
				if (($genome_id ne $current_genome) && (!(exists $genomes_not_found{$genome_id}))){
					%genes = ();
					$current_genome = $genome_id;
					my $proteome_file = $proteome_dir . "/" . $genome_id . $proteome_file_prefix;
					if (-e $proteome_file) {
						open (PROTFILE, $proteome_file) or die ("Unable to open $proteome_file ");
						my $flag = 0;
						my $fasta_line = "";
						my $protein_sequence = "";
						my $protein_id = "";
						while ($fasta_line = <PROTFILE>) {
							chomp $fasta_line;
							if (($fasta_line =~ /^\>/) && $flag) {
								$genes{$protein_id} = $protein_sequence; #put PREVIOUS protein to %genes hash
								$protein_id = $fasta_line;
								$protein_id =~ s/^\>//;
								$protein_sequence = "";
							} elsif ($fasta_line =~ /^\>/) { #the first protein
								$flag = 1;
								$protein_id = $fasta_line;
								$protein_id =~ s/^\>//;
							} elsif ($flag) {
								$protein_sequence .= $fasta_line;
							}
						}
						$genes{$protein_id} = $protein_sequence; #put the last protein to %genes hash

						close PROTFILE;
	#					print "Genes found:\n";
	#					for my $proteinid (keys %genes) {print $proteinid ."\t" . $genes{$proteinid} . "\n";}
						
					} else {
						$genomes_not_found{$genome_id} = $subsystem_id;
					}
				}
				if (exists $genomes_not_found{$genome_id}) {
					#skip it
				} elsif (!(exists $genes{$gene_id})) {
					print "Protein $gene_id not found in $genome_id genome \n";
				} elsif (exists $proteins_written{$gene_id}) {
					print "Protein $gene_id already written to file \n";
				} else {
					print OUTFILE ">" . $subsystem_id . "_" . $role_id . "_" . $gene_id . "\n" . $genes{$gene_id} . "\n";
					$proteins_written{$gene_id} = $subsystem_id . "_" . $role_id;			
				}

			}
		}
		close OUTFILE;
		close SUBSFILE;
		%proteins_written=(); 	# one protein may be a member of different subsystems, so a list of processed proteins is empty when we go to the next subsystem
		%genes = ();
		print $subsystem_name . "\n";
	}	
}

print "Proteomes not found (if any):\n";
print join (" ", keys %genomes_not_found) . "\n";
print "Done\n";
exit (0);

#####################
###  SUBROUTINES  ###
#####################
sub get_genome_id {
	my ($gene_id) = @_;
	$gene_id =~ s/^fig\|//;
	$gene_id =~ s/.peg.*//;
	return $gene_id
}