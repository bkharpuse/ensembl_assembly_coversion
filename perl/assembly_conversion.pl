use strict;
use warnings;
use diagnostics;
use Getopt::Long;
use JSON::XS;
use Bio::EnsEMBL::Registry;

sub get_help_message {
    print "usage: assembly_conversion.pl -c <CHROMOSOME> -st <START> -en <END> [-sp <SPECIES>] [-fr <SOURCE_ASM>] [-to <DEST_ASM>] [-f <FILE_NAME>] [-str <STRAND>] [-h]\n";
    print "help:\n";
    print "-h | --help                        Shows help message\n\n";

    print "-c | --chromosome <CHROMOSOME>     Name of the chromosome [1-22] X Y\n";
    print "                                   Required\n\n";

    print "-st | --start <START>              Start point of chromosome\n";
    print "                                   Required\n\n";

    print "-en | --end <END>                  End point of chromosome\n";
    print "                                   Required\n\n";

    print "-sp | --species <SPECIES>          Species name/alias\n";
    print "                                   Optional\n";
    print "                                   Default value : human\n\n";

    print "-fr | --source_assembly <SRC_ASM>  Version of the source/input assembly\n";
    print "                                   Optional\n";
    print "                                   Default value : GRCh38\n\n";
    

    print "-to | --dest_assembly <DEST_ASM>   Version of the destination/output assembly\n";
    print "                                   Optional\n";
    print "                                   Default value : GRCh37\n\n";

    print "-f | --file <FILE_NAME>            Dumps Json output data in the given file\n";
    print "                                   Optional\n";
    print "                                   Default : output.json\n\n";

    print "-str | --strand <STRAND>           Value of strand\n";
    print "                                   Optional\n";
    print "                                   Default value : 1\n";
    die " ";
}

sub write_to_json_file {
    printf("Writing to json file.");
    my ($file_name, @projection) = @_;
    my $json = JSON::XS->new->utf8->pretty(1);
    my $to_json = $json->encode({mappings => \@projection});
    open my $fh, ">", $file_name;
    print $fh $to_json;
    close $fh;
    printf("Data is available in output json file..");
}

sub get_arguments {
    my ($chromosome, $start, $end);
    my ($species, $src_asm, $dest_asm, $file_name, $strand) = ('Human', 'GRCh38', 'GRCh37', 'output.json', '1');

    GetOptions(
        'species|sp=s' => \$species,
        'chromosome|c=s' => \$chromosome,
        'start|st=i' => \$start,
        'end|en=i' => \$end,
        'source_assembly|fr=s' => \$src_asm,
        'dest_assembly|to=s' => \$dest_asm,
        'file|f=s' => \$file_name,
        'strand|str=s' => \$strand,
        'h|help!'
    ) or get_help_message();

    if (!defined $chromosome || !defined $start || !defined $end) {
        get_help_message();
    }

    printf("Data to be used for assembly conversion:
          species: $species, source_asm: $src_asm, dest_asm: $dest_asm, chromosome: $chromosome start: $start, end: $end, file_name: $file_name, strand: $strand\n");
    return $chromosome, $species, $start, $end, $src_asm, $dest_asm, $file_name, $strand;
}

sub connect_to_db {
  printf("Connecting to EnsEMBL::Registry... DB\n");
  my $registry = 'Bio::EnsEMBL::Registry';
  $registry->load_registry_from_db(
      -host => 'ensembldb.ensembl.org',
      -user => 'anonymous',
  );
  printf("Successfully connected to EnsEMBL DB.\n");
  return $registry;
}

sub get_object {
  my ($segment, $old_slice) = @_;
  my $new_slice = $segment -> to_Slice();

  my $new_coord_sys  = $new_slice->coord_system()->name();
  my $new_seq_region = $new_slice->seq_region_name();
  my $new_start      = $new_slice->start();
  my $new_end        = $new_slice->end();
  my $new_strand     = $new_slice->strand();
  my $new_version    = $new_slice->coord_system()->version();

  my $old_coord_sys  = $old_slice->coord_system()->name();
  my $old_seq_region = $old_slice->seq_region_name();
  my $old_start      = $old_slice->start() + $segment->from_start() - 1,;
  my $old_end        = $old_slice->start() + $segment->from_end() - 1,;
  my $old_strand     = $old_slice->strand();
  my $old_version    = $old_slice->coord_system()->version();

    my $data = {"original" => {
    "coord_system" => $old_coord_sys,
    "seq_region_name" => $old_seq_region,
    "start" => $old_start,
    "end" => $old_end,
    "assembly" => $old_version,
    "strand" => $old_strand
    }, "mapped" => {
    "coord_system" => $new_coord_sys,
    "seq_region_name" => $new_seq_region,
    "start" => $new_start,
    "end" => $new_end,
    "assembly" => $new_version,
    "strand" => $new_strand
    }};
    return $data;
}

sub show_data_mappings {
    my ($registry, $chromosome, $species, $start, $end, $src_asm, $dest_asm, $file_name, $strand) = @_;

    my $slice_adaptor = $registry->get_adaptor($species, 'Core', 'Slice');
    my $old_slice = $slice_adaptor->fetch_by_region( 'chromosome', $chromosome, $start, $end, $strand, $src_asm);

    my $old_coord_sys  = $old_slice->coord_system()->name();
    my $old_seq_region = $old_slice->seq_region_name();
    my $old_start      = $old_slice->start();
    my $old_end        = $old_slice->end();
    my $old_strand     = $old_slice->strand();
    my $old_version    = $old_slice->coord_system()->version();

    my $projection = $old_slice->project('chromosome', $dest_asm);
    printf("-------OLD SLICE INFO[$src_asm]---------------------CONVERTED SLICE INFO[$dest_asm]\n");
    my @data_array = ();
    foreach my $segment (@{$projection}) {
        printf( "%s:%s:%s:%d:%d:%d-----%s\n",
              $old_coord_sys,
              $old_version,
              $old_seq_region,
              $old_start + $segment->from_start() - 1,
              $old_start + $segment->from_end() - 1,
              $old_strand,
              $segment->to_Slice()->name() );
        my $data = get_object($segment, $old_slice);
        push(@data_array, $data);
    }
    write_to_json_file($file_name, @data_array);
}

unless(caller) {
  my ($chromosome, $species, $start, $end, $src_asm, $dest_asm, $file_name, $strand) = get_arguments();
  my $registry = connect_to_db();
  show_data_mappings($registry, $chromosome, $species, $start, $end, $src_asm, $dest_asm, $file_name, $strand);
  printf("Done\n");
}
