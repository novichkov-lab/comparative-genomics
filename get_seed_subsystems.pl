#! /usr/bin/perl
use strict;
use warnings;
use SAPserver;

my $sapServer = SAPserver->new();

######################################
###  Download all SEED subsystems  ###
######################################

my $work_dir = "seed_subsystems";
my $limit = -1;
my $subsystems_file = "subsystems_list.txt";
my $roles_file = "roles_list.txt";
my $subsystem_filename_prefix = "_subsystem.txt";
#my $subsystem_name = "Denitrification";
my @subsystems =();

if (@ARGV == 2) {
	$work_dir = $ARGV[0];
	$limit = $ARGV[1];
} elsif (@ARGV == 1) {
	$work_dir = $ARGV[0];
} else {
	print "Usage: perl get_seed_subsystems.pl <output folder> <number of subsystems (optional)>\n";
	exit(0);
};
if (($work_dir ne "")&&(!(-e $work_dir))) {
	print "Directory $work_dir does not exist!\n";
	exit(1);
}

#Create files with list of all subsystems and list of all roles
$subsystems_file = $work_dir . "/" . $subsystems_file;
open (SUBSFILE, ">$subsystems_file") or die ("Unable to open file $subsystems_file");
my $subsysHash =        $sapServer->all_subsystems({
                                -usable => 1,
                                -aux => 1
                            });

my $i = 0;
for my $id (keys %$subsysHash) {
	push @subsystems, $id;
	print SUBSFILE $i."\t".$id."\n";
	$i++;
}
close SUBSFILE;

#Create files for individual subsystems and a file with list of all roles
$roles_file = $work_dir . "/" . $roles_file;
open (ROLESFILE, ">$roles_file") or die ("Unable to open file $roles_file");

$i = 0;
for my $subsystem_id (@subsystems){
	if ($limit == 0) {
		last;
	} else {
		$limit-- ;
	}
	print $subsystem_id. "\n";
	my $subsystem_filename = $work_dir . "/" . $i . $subsystem_filename_prefix;
	open (OUTFILE, ">$subsystem_filename") or die ("Unable to open file $subsystem_filename");
	my $subsysHash =        $sapServer->get_subsystems({
                                -ids => [$subsystem_id],
								});

	for my $sub_id (keys %$subsysHash) {
		my $subsystem = $subsysHash->{$sub_id};

		my $roles = $subsystem->{"roles"};
		my $j = 0;
		for my $role (@$roles) {
			print ROLESFILE $i . "\t" . $j . "\t" . $$role[0]. "\t".$$role[1]. "\t".$$role[2]. "\n";
			$j++;
		}

		my $spreadsheet = $subsystem->{"spreadsheet"};
		for my $spreadsheet_entry (@$spreadsheet){
#			print OUTFILE   $$spreadsheet_entry[0]."\t".$$spreadsheet_entry[1]."\t".$$spreadsheet_entry[2]."\t".$$spreadsheet_entry[3];
			for my $entry (@$spreadsheet_entry[4]){
				my $j = 0;
				for my $feature_id (@$entry){
					for my $gene_id (@$feature_id) {
						print OUTFILE $i . "\t" . $j . "\t" . $gene_id . "\n";
						
					}
					$j++;
				}
			}
			print OUTFILE "\n";
		}

		
	}
	$i++;
}
close ROLESFILE;
exit(0);

#####################
###  SUBROUTINES  ###
#####################
