# Perl CLI to convert ensembl assembly from GRCh38 to GRCh37 and vice-versa
This perl command line option gives you the ability to convert one assembly coordinates to another one.
for example: GRCh38 to GRCh37 or GRCh37 to GRCh38

# Description of CLI

usage: assembly_conversion.pl -c <CHROMOSOME> -st <START> -en <END> [-s <SPECIES>] [-fr <SOURCE_ASM>] [-to <DEST_ASM>]  [-f <FILE_NAME>] [-str <STRAND>] [-h]
    help:
    -h | --help                        Shows help message

    -c | --chromosome <CHROMOSOME>     Name of the chromosome [1-22] X Y.
                                       Required

    -st | --start <START>              Start point of chromosome.
                                       Required

    -en | --end <END>                  End point of chromosome.
                                       Required

    -sp | --species <SPECIES>          Species name/alias
                                       Optional
                                       Default value : human

    -fr | --source_assembly <SRC_ASM>  Version of the source/input assembly
                                       Optional
                                       Default value : GRCh38

    -to | --dest_assembly <DEST_ASM>   Version of the destination/output assembly
                                       Optional
                                       Default value : GRCh37

    -f | --file <FILE_NAME>            Dumps Json output data in the given file
                                       Optional
                                       Default : output.json

    -str | --strand <STRAND>           Value of strand
                                       Optional
                                       Default value : 1
                                       
# CLI Example:
  perl assembly_mapping.pl --chromosome 10 --start 25000 --end 30000
  
  perl assembly_mapping.pl --chromosome 10 --start 25000 --end 30000 -f assembly.json
