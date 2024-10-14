=comment

This script checks to see if all homonyms are ordered.  It will:
1. Create a report indicating which records are missing homographs
2. Write a new file adding the homographs where needed.

TODO:
FIXED 1. Add a check for duplicate homographs.
2. Figure out a way to send messages to the user on Windows.
3. Address the issue of encountering homographs that begin with a number larger than 1.  Example:
\lx a

\lx a
\hm 2

would result in

\lx a
\hm 3

\lx a
\hm 4

Although this will work in FLEx, it creates an undesireable condition - a quick look at the
db seems to indicate there are 4, not 2 lexeme a's.

Version:
Created: Cindy Mooney - 2/24/18
Modified: Cindy Mooney - 2/26/18  Fixed 1. Updated log messages.
Modified:	2/13/20	Beth Bryson	Add more comments

Usage:
Edit this file to add infile, outfile, and logfile names.
Example:
my $infile = 'lex.db';		# don't edit these lines, they are commented out
my $outfile= 'newlex.db';
my $log_file= 'myLog.txt';

To execute:
Windows: Double click on this script from Windows Explorer -or- open a cmd prompt, navigate
to the same location as this script, type in 'perl add_hm.pl' without the single quotes

Unix: from the command prompt type in 'perl add_hm.pl' without the single quote




=cut

# More TODO items:
# - Currently strips all blank lines from file.
#	Should preserve existing blank lines.
# - Strips the first line of the file, and/or the \_sh lines.
#	User should check the output file, and restore any initial lines
#	that are missing.
# - Doesn't consider \se fields to be candidates for homograph numbers,
# 	but FLEx does.  Need to adjust the calculations to take subentries
#	into account.  (and allow user to specify subentry markers)

use feature ':5.10';
use Data::Dumper qw(Dumper);


# EDIT THESE VARIABLES TO SPECIFY FILENAMES FOR INPUT, OUTPUT, AND LOG FILES
my $infile = '';
my $outfile= '';
my $log_file= '';


my $row;
my @file_Array;
my %lx_Array;
my $hWord;
my $hm;
my $hWord_hm;
my $lxRow;
my @tmpRec;
my $TO_PRINT = "TRUE";
my $DUPLICATE = "FALSE";

open(my $fhlogfile, '>:encoding(UTF-8)', $log_file)
	or die "Could not open file '$log_file' $!";

open(my $fhoutfile, '>:encoding(UTF-8)', $outfile)
	or die "Could not open file '$outfile' $!";

open(my $fhinfile, '<:encoding(UTF-8)', $infile)
  or die "Could not open file '$infile' $!";

#1st pass - build a hash lexeme->[hm,hm,hm] or lexeme->[0] if it is not a homonym.
#Read the file into memory

while ( $row = <$fhinfile> ) {

	if ( $row =~ /^\\lx/ ) {
		$lxRow = $row;

		#add the headword to the controlArray.
		$hWord = substr $row, 4;

 		#remove any extra spaces at the beginning and end of the headword.
                $hWord =~ s/^\s+|\s+$//g;

		if ( !exists $lx_Array{$hWord} ){
			@{$lx_Array{$hWord}{index}} = 0;
		}
		else {
	 		@tmpRec = @{$lx_Array{$hWord}{index}};
			push @tmpRec, 0;
			@{$lx_Array{$hWord}{index}} = @tmpRec;
		}

		push @file_Array, $lxRow;
	}
	elsif ( $row =~ /^\\hm/ ) {
		my $hm_row = $row;
		#get the hm number
		$row =~ /\\hm\s+(\d+)/;
		$hm = $1;
		say $hm;
 		#remove any extra spaces at the beginning and end of the hm.
		#$hm =~ s/^\s+|\s+$//g;
	
		# add the hm number to the array associated with the key.
		
	 	@tmpRec = @{$lx_Array{$hWord}{index}};
		pop @tmpRec;
		push @tmpRec, $hm;
		@{$lx_Array{$hWord}{index}} = @tmpRec;
		push @file_Array, $hm_row;
	}
	elsif ( $row =~ /^\\_sh/  || $row =~ /^$/ ) {

		#do nothing

	}
	else {

		push @file_Array, $row;

	}

}


#print Dumper(\%lx_Array);

#I've built my hash array of lexeme->[0|hm+].   Iterate through each of the hm lists and
#fill in the zero's with the next largest number if the record is a homonym.
#

foreach my $key ( keys %lx_Array ){
my %seen;
my $hm_val;
my @dup_rec;

	$DUPLICATE = "FALSE";
	@tmpRec = @{$lx_Array{$key}{index}};
	if ( scalar @tmpRec > 1 ){
		#this is a homonym
		#check here to see if we have any duplicate \hm for this lexeme.
	 	@dup_rec = @tmpRec;
		@dup_rec = grep { $_  != 0 } @dup_rec;
		say @dup_rec;
		foreach $hm_val (@dup_rec){
			next unless $seen{$hm_val}++;
			$DUPLICATE = "TRUE";
		
		}
		if ($DUPLICATE eq "TRUE"){
			write_to_log(qq(CANNOT PROCEED: Duplicate homograph value for lexeme $key));
			$TO_PRINT = "FALSE";
	 	}	
		else {
			for (my $i=0; $i< scalar @tmpRec; $i++ ){
				if ( $tmpRec[$i] == 0 ){
					#get max number
					my @sorted = sort { $a <=> $b } @tmpRec;
					my $largest = pop @sorted;
					$largest++;
					@tmpRec[$i]=$largest;
					write_to_log("Updating lexeme $key with hm $largest");
				}
			}
		}
	}
	@{$lx_Array{$key}{index}} = @tmpRec;
}

			

#print Dumper(\%lx_Array);


write_to_log("Input file $infile Output file $outfile");

sub write_to_log{

        my ($message) = @_;
	        print $fhlogfile "$message\n";
}

if ($TO_PRINT eq "TRUE"){

	foreach my $r (@file_Array){

		if ( $r =~ /^\\lx/ ){
	
			$hWord = substr $r, 4;
       		         $hWord =~ s/^\s+|\s+$//g;
			print $fhoutfile "\n";
			print $fhoutfile $r;

			my $hm = shift @{$lx_Array{$hWord}{index}};
			if ( $hm > 0 ){
				print $fhoutfile "\\hm $hm\n";
			}
		}
		elsif ($r =~ /^\\hm/) {}
		else { print $fhoutfile $r; }
	}
}
else {
	write_to_log (qq(Duplicate \\hm values have been found. SFM file must be corrected.));
	print $fhoutfile (qq(No data has been written. See details in log file.))

}

close $fhlogfile;
close $fhinfile;
close $fhoutfile;

