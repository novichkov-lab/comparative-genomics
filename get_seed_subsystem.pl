#! /usr/bin/perl
use strict;
use warnings;
use SAPserver;

my $sapServer = SAPserver->new();

#################################
###  Download SEED subsystem  ###
#################################

my $work_dir = "data";
my $subsystem_filename = "subsystem.txt";
my $subsystem_name = "Denitrification";
my @subsystem_roles =();
my %subsystem_genes = ();

if (@ARGV == 3) {
	$work_dir = $ARGV[0];
	$subsystem_filename = $ARGV[1];
	$subsystem_name = $ARGV[2];
	$subsystem_name =~ s/\"//;
} else {
	print "Usage: perl get_seed_subsystem.pl <output folder> <output file name> <SEED subsystem ID>\n";
	print "if SEED subsystem ID contains spaces, put quotes around it\n";
	exit(0);
};
if (($work_dir ne "")&&(!(-e $work_dir))) {
	print "Directory $work_dir does not exist!\n";
	exit(1);
}

open (OUTFILE, ">$subsystem_filename") or die ("Unable to open file $subsystem_filename");

my $subsysHash =        $sapServer->get_subsystems({
                                -ids => [$subsystem_name],
                            });

for my $sub_id (keys %$subsysHash) {
	my $subsystem = $subsysHash->{$sub_id};
#	my $curator = $subsystem->{"curator"};
#	print $curator . "\n";
#	print $subsystem->{"version"}."\n";
#	print $subsystem->{"notes"}."\n";
#	print $subsystem->{"desc"}."\n";
	print OUTFILE "Genome\tRegion\tCurated\tVariant";
	my $roles = $subsystem->{"roles"};
	for my $role (@$roles) {
		print OUTFILE "\t".$$role[0];
		push @subsystem_roles,$$role[0];
#		print $$role[0]. "\t".$$role[1]. "\t".$$role[2]. "\n";
	}
	print OUTFILE "\n";
	my $spreadsheet = $subsystem->{"spreadsheet"};
	for my $spreadsheet_entry (@$spreadsheet){
		print OUTFILE $$spreadsheet_entry[0]."\t".$$spreadsheet_entry[1]."\t".$$spreadsheet_entry[2]."\t".$$spreadsheet_entry[3];
		my $i = 0;
		for my $entry (@$spreadsheet_entry[4]){
			for my $feature_id (@$entry){
				print OUTFILE "\t".join (",",@$feature_id);
				for my $gene_id (@$feature_id) {
					$gene_id = $subsystem_roles[$i]."_".$gene_id;
					$subsystem_genes{$gene_id} = $$spreadsheet_entry[0];
				}
			}
			$i++;
		}
		print OUTFILE "\n";
	}
}

print OUTFILE "\nGene locations\n";
my $limit = 2;
for my $gene (keys %subsystem_genes){
	print OUTFILE get_location($gene)."\n";
	$limit++;
	if ($limit == 20) {last;}
}


close OUTFILE;
exit(0);

#####################
###  SUBROUTINES  ###
#####################

sub get_location {
	my ($gene) = @_;
	my @role_geneid = split ("_", $gene);
	my $ret_val = ""; 
	
	my $featureHash =        $sapServer->fid_locations({
                                -ids => [$role_geneid[1]],
                                -boundaries => 0
                            });

	for my $id (keys %$featureHash) {
		$ret_val .= $role_geneid[0]."\t".$id;
		my $locations = $featureHash->{$id};
		$ret_val .= "\t".extract_accession(@$locations[0]);
		$ret_val .= "\t".@$locations[0];
	}
	
	return $ret_val;
}

sub extract_accession {
	my ($location) = @_;
	$location =~ s/^.*\://;
	$location =~ /(^[a-zA-Z]*_*[a-zA-Z]*\d*)/;
	return $1;
}