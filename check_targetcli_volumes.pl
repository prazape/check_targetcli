#! /usr/bin/perl
# vim: tabstop=2 shiftwidth=2 expandtab 

# Author: Petr Prazak prazape@gmail.com
# Date: 2024-08-03
# Description: This script checks the available backstores and provides warnings
# and critical alerts based on the defined thresholds.
# 
# License: This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

use Data::Dumper;
use strict;
use warnings;
use utf8;
use Getopt::Long;
binmode(STDOUT, "encoding(UTF-8)");

#
##
### Function definitions
##
#

# Displays usage information for the script
sub show_usage{
  print "Usage: check_da_zkapalnovac [OPTIONS]\n";
  print "\n";
  print "Options:\n";
  print "  -h, --help                             Show this help message and exit\n";
  print "  -c, --critical VALUE                   Critical if total number of backstores is less than VALUE\n";
  print "  -w, --warning VALUE                    Warning if total number of backstores is less than VALUE\n";
  print "  --bw, --block-warning VALUE            Warning if there are are less than VALUE block backstores\n";
  print "  --bc, --block-critical VALUE           Critical if there are are less than VALUE block backstores\n";
  print "  --fw, --fileio-warning VALUE           Warning if there are are less than VALUE fileio backstores\n";
  print "  --fc, --fileio-critical VALUE          Critical if there are are less than VALUE fileio backstores\n";
  print "  --pw, --pscsi-warning VALUE            Warning if there are are less than VALUE pscsi backstores\n";
  print "  --pc, --pscsi-critical VALUE           Critical if there are are less than VALUE pscsi backstores\n";
  print "  --rw, --ramdisk-warning VALUE          Warning if there are are less than VALUE ramdisk backstores\n";
  print "  --rc, --ramdisk-critical VALUE         Critical if there are are less than VALUE ramdisk backstores\n";
  print "  -v, --verbose                          Increase verbosity level\n";
  print "  -q, --quiet                            Suppress output\n";
  print "\n";
  exit;
}

# Sets the result code to the highest severity encountered
sub set_result{
  my ($result_code_ref, $code) = @_;

  # Dereference and set the value
  if ($$result_code_ref < $code){
    $$result_code_ref = $code;
  }
}

# Prints a message based on the verbosity level
sub print_message {
  my ($level, $message) = @_;

  # Log the message if the current verbosity level is equal to or higher than the specified level
  if ($main::verbose >= $level) {
      print($message);
  }
}

# Prints a series of messages, formatting with commas except for the last message
sub print_loop_messages {
  my ($level, @messages) = @_;

  my $last_index = $#messages;
  my $index = 0;
  foreach my $message (@messages) {
    if ($last_index != $index++) {
      print_message($level, $message . ", ");
    } else {
      print_message($level, $message . " ");
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

# Define return codes and strigns
my %return_codes = (
    "ok"       => 0,
    "warning"  => 1,
    "critical" => 2,
    "unknown"  => 3 
  );

my %return_codes_to_strings = (
    0 => "OK:",
    1 => "WARN:",
    2 => "CRIT:",
    3 => "UNKNOWN" 
  );

my $return_code = $return_codes{"ok"};

# Prepare thresholds arrays for warnings and criticals
my %warnings = (
    "total"   => 0,
    "block"   => 0,
    "fileio"  => 0,
    "pscsi"   => 0,
    "ramdisk" => 0 
  );

my @warning_messages;

my %criticals = (
    "total"   => 0,
    "block"   => 0,
    "fileio"  => 0,
    "pscsi"   => 0,
    "ramdisk" => 0 
  );

my @critical_messages;

our $verbose = 1;

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
### Retrieve and parse the input
##
#
my $input = `/usr/bin/targetcli ls`;

# Match the "backstores" paragraph using a regular expression
if ($input =~ /(^\ \ o- backstores.+?)\n(.+?)(^\ \ o)/ms) {

  my $backstores = $2;  
  
  # For each backstore type, read count and load backstores info
  while ($backstores =~ /^\s*\|\s+o- (\w+)(?:\ \.+\ [[]Storage Objects:\s+(\d)\s?[]])(.*?)(?=^\s*\|\s+o- \w+|\Z)/msg) {

    $storage_type = $1;
    $storage_count = $2;
    $storage_details = $3;

    $backstores_counts{$storage_type} = $storage_count;

    print_message(2, "Storage Type: $storage_type\n");
    print_message(2, "  Number of storages: $storage_count");

    if ($criticals{$storage_type} > $storage_count) {
      print_message(2, " -> CRITICAL: Less than expected ($criticals{$storage_type})");
      push(@critical_messages, $storage_type);
      set_result(\$return_code, $return_codes{"critical"});
    }
    elsif ($warnings{$storage_type} > $storage_count) {
      print_message(2, " -> WARNING: Less than expected ($warnings{$storage_type})");
      push(@warning_messages, $storage_type);
      set_result(\$return_code, $return_codes{"warning"});
    }

    print_message(2, "\n");

    # Print storage details
    while ($storage_details =~ /^\s*\|\s+\|\ o-\s+(.*?)\ \./msg) {
      print_message(3, "  Storage name: $1\n");
    }
    print_message(2, "\n");
    print_message(2, "  Details: $storage_details\n");
  }
}
else {
  print "UNKNOWN: Can't find backstores paragraph.\n";
  exit 4;
}

# Calculate total count of all backstores
my $total_count = 0;
foreach my $count (values %backstores_counts) {
  $total_count += $count;
}
print_message(2, "Total datastore count: $total_count");

if ($criticals{"total"} > $total_count) {
  print_message(2, " -> CRITICAL: Less than expected ($criticals{'total'})");
  push(@critical_messages, "total");
  set_result(\$return_code, $return_codes{"critical"});
}
elsif ($warnings{"total"} > $total_count) {
  print_message(2, " -> WARNING: Less than expected ($warnings{'total'})");
  push(@warning_messages, "total");
  set_result(\$return_code, $return_codes{"warning"});
}

# Show message indicating which limit was problematic
if ($return_code == $return_codes{"critical"}) {
  print_message(1, $return_codes_to_strings{$return_code} . " Not enough ");
  print_loop_messages(1, @critical_messages);
  print_message(1, "backstores\n");
}
elsif ($return_code == $return_codes{"warning"}) {
  print_message(1, $return_codes_to_strings{$return_code} . " Not enough ");
  print_loop_messages(1, @warning_messages);
  print_message(1, "backstores\n");
}
elsif ($return_code == $return_codes{"ok"}) {
  print_message(1, $return_codes_to_strings{$return_code} . " Found $total_count backstore" . ($total_count > 1 ? "s" : ""));
}
else {
  print_message(1, $return_codes_to_strings{4});
}

exit($return_code);
