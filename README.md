# AddHomographs
Script for verifying homographs in an SFM file, and adding them where needed

REQUIRED MODULES:  None

INPUT/OUTPUT FILES: specified in the script (search for "EDIT")

USAGE:	perl add_hm.pl

LOGFILE: writes a logfile indicating:
 * Which lexemes had their \hm fields updated
 * Name of input and output files

SAMPLE DATA:
 There is a folder called SampleData with files for testing this script
 to see how it works.
   * add_hm-Eng.pl	The script, customized with filenames for the sample data
   * SampleEnglish-BeforeAddHM.db	Sample input file
   * SampleEnglish-AfterAddHM.db	Shows what the output should look like
   * Log-AddHM.txt					Show what the logfile looks like for this data

SAMPLE USAGE:
 To run this customized script on this sample data, go to the folder where
 the sample data file is, and type this on the command line:

   perl add_hm.pl

