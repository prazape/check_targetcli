#! /usr/bin/perl
# vim: tabstop=2 shiftwidth=2 expandtab 

use Data::Dumper;
use strict;
use warnings;
# use diagnostics;
use utf8;
#use Monitoring::Plugin;

use Getopt::Long;
#use List::Util 'any';
binmode(STDOUT, "encoding(UTF-8)");

#
##
### Function definitions
##
#

sub show_usage{
  print "Usage: check_da_zkapalnovac [OPTIONS]\n";
  print "\n";
  print "Options:\n";
  print "  -h, --help                             Show this help and quit\n";
  print "  -c, --critical VALUE                   Warning if total number of backstores is less then\n";
  print "  -W, --warning VALUE                    Critical value for total number of backstores is less then\n";
  print "  -bw, --block-warning VALUE             Warning value for block backstores is less then\n";
  print "  -bc, --block-critical VALUE            Critical value for block backstores is less then\n";
  print "  -fw, --fileio-warning VALUE            Warning value for fileio backstores is less then\n";
  print "  -fc, --fileio-critical VALUE           Critical value for fileio backstores is less then\n";
  print "  -pw, --pscsi-warning VALUE             Warning value for pscsi backstores is less then\n";
  print "  -pc, --pscsi-critical VALUE            Critical value for pscsi backstores is less then\n";
  print "  -rw, --ramdisk-warning VALUE           Warning value for ramdisk backstores is less then\n";
  print "  -rc, --ramdisk-critical VALUE          Critical value for ramdisk backstores is less then\n";
  print "  -v, --verbose                          Increase verbosity level\n";
  print "  -q, --quiet                            Suppress output\n";
  print "\n";
  exit;
}

sub set_result{
  my ($result_code_ref, $code) = @_;

  # Dereference and set the value
  if ($$result_code_ref lt $code){
    $$result_code_ref = $code;
  }

}

sub print_message {
    my ($level, $message) = @_;

    # Log the message if the current verbosity level is equal to or higher than the specified level
    if ($main::verbose >= $level) {
        print($message);
    }
}

sub print_loop_messages{

  my ($level,@messages) = @_;

  my $last_index = $#messages;
  my $index = 0;
  foreach my $message (@messages){
    if ($last_index ne $index++){
      print_message ($level,$message.", ");
    }
    else{
      print_message ($level,$message." ");
    }
  }
}

#
##
### Prepare variables
##
#
my $storage_type;
my $storage_count;
my %backstores_counts;
my $storage_details;

my %return_codes = (  "ok"       => 0,
                      "warning"  => 1,
                      "critical" => 2,
                      "unknown"  => 3 );

my %return_codes_to_strings = ( 0 => "OK:",
                                1 => "WARN:",
                                2 => "CRIT:",
                                3 => "UNKNOWN" );

my $return_code = $return_codes{"ok"};

my %warnings = (  "total"   => 0,
                  "block"   => 0,
                  "fileio"  => 0,
                  "pscsi"   => 0,
                  "ramdisk" => 0 );

my @warning_messages;

my %criticals = ( "total"   => 0,
                  "block"   => 0,
                  "fileio"  => 0,
                  "pscsi"   => 0,
                  "ramdisk" => 0 );

my @critical_messages;

our $verbose=1;

#
##
### Parse parameters
##
#
Getopt::Long::Configure("bundling");
GetOptions(
  "h|help"                      => \&show_usage,                                    # function
  "w|warning=s"                 => \$warnings{"total"},                             # string
  "c|critical=s"                => \$criticals{"total"},                            # string
  "bw|block-warning=s"          => \$warnings{"block"},                             # string
  "bc|block-critical=s"         => \$criticals{"block"},                            # string
  "fw|fileio-warning=s"         => \$warnings{"fileio"},                            # string
  "fc|fileio-critical=s"        => \$criticals{"fileio"},                           # string
  "pw|pscsi-warning=s"          => \$warnings{"pscsi"},                             # string
  "pc|pscsi-critical=s"         => \$criticals{"pscsi"},                            # string
  "rw|ramdisk-warning=s"        => \$warnings{"ramdisk"},                           # string
  "rc|ramdisk-critical=s"       => \$criticals{"ramdisk"},                          # string
  "v|verbose+"                  => \$verbose,                                       # incrementable
  "q|quiet"                     => sub { $verbose = 0 }
) or show_usage();

#
##
### Return Values
##
#
my $input = `targetcli ls`;

# Match the "backstores" paragraph using a regular expression
if ($input =~ /(^\ \ o- backstores.+?)\n(.+?)(^\ \ o)/ms) {
  
  my $backstores = $2;  
    
  # For each backstore type read count and load backstores info
  while ($backstores =~ /^\s*\|\s+o- (\w+)(?:\ \.+\ [[]Storage Objects:\s+(\d)\s?[]])(.*?)(?=^\s*\|\s+o- \w+|\Z)/msg) {

    $storage_type = $1;
    $storage_count = $2;
    $storage_details = $3;

    $backstores_counts{ $storage_type } = $storage_count;

    print_message (2,"Storage Type: $storage_type\n");
    print_message (2,"  Number of storages: $storage_count");

    if($criticals{ $storage_type } gt $storage_count){
      print_message (2," -> CRITICAL: Less then wanted.($criticals{ $storage_type })");
      push(@critical_messages,$storage_type);
      set_result(\$return_code,$return_codes{"critical"});
    }
    elsif($warnings{ $storage_type } gt $storage_count){
      print_message (2," -> WARNING: Less then wanted.($warnings{ $storage_type })");
      push(@warning_messages,$storage_type);
      set_result(\$return_code,$return_codes{"warning"});
    }

    print_message (2,"\n");

    while ($storage_details =~ /^\s*\|\s+\|\ o-\s+(.*?)\ \./msg) {

      print_message (3,"  Storage name: $1\n");

    }
    print_message (2,"\n");
    print_message (2, "  Details: $storage_details\n");

  }
}

else {
    print "UNKNOWN: Can't find backstores paragraph.\n";
    exit (4);
}

# print "counts:\n";
# print Dumper %backstores_counts;
# print "\n";

# print "warnings:\n";
# print Dumper %warnings;
# print "\n";

# print "criticals:\n";
# print Dumper %criticals;
# print "\n";
my $total_count = 0;
foreach my $count (values %backstores_counts) {
  $total_count += $count;
}
print_message (2,"Total datastores count: $total_count");

if($criticals{ "total" } gt $total_count){
  print_message (2," -> CRITICAL: Less then wanted.($criticals{ 'total' })");
  push(@critical_messages,"total");
  set_result(\$return_code,$return_codes{"critical"});
}
elsif($warnings{ "total" } gt $total_count){
  print_message (2," -> WARNING: Less then wanted.($warnings{ 'total' })");
  push(@warning_messages,"total");
  set_result(\$return_code,$return_codes{"warning"});
}

# Show message what limit was problematic
if ($return_code eq $return_codes{"critical"}){
  print_message (1, $return_codes_to_strings{$return_code}." Not enough ");
  print_loop_messages(1,@critical_messages);
  print_message (1,"backstores\n");
}
elsif ($return_code eq $return_codes{"warning"}){
  print_message (1, $return_codes_to_strings{$return_code}." Not enough ");
  print_loop_messages(1,@warning_messages);
  print_message (1,"backstores\n");
}
elsif ($return_code eq $return_codes{"ok"}){
  print_message (1, $return_codes_to_strings{$return_code}." Found $total_count backstore". ($total_count gt 1?"s":""));
}
else{
  print_message (1, $return_codes_to_strings{4});
}

exit($return_code);