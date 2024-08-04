# Check TargetCLI Volumes

This script checks the status of backstores managed by `targetcli` and provides warnings and critical alerts based on user-defined thresholds. It is intended as nagios/icinga monitoring plugin to ensure that the number of backstores does not fall below specified limits.

## Features

- **Threshold-based alerts**: Set warning and critical thresholds for the total number of backstores and individual types (block, fileio, pscsi, ramdisk). Probably only critical thresholds will be used, but warnings are also provided/supported.
- **Verbosity control**: Adjust the level of output detail with the `-v` option. The default verbosity level is 1, but it can go up to 4.
- **Quiet mode**: Suppress all output with the `-q` option.

## Prerequisites

- Perl
- `targetcli` tool installed and accessible

## Installation

1. Clone the repository:

   ```sh
   git clone https://github.com/prazape/check_targetcli.git
   ```

2. Navigate to the directory:

   ```sh
   cd check_targetcli
   ```

3. Ensure the script is executable:

   ```sh
   chmod +x check_targetcli_volumes.pl
   ```

## Usage

```sh
./check_targetcli_volumes.pl [OPTIONS]
```

### Options

- `-h, --help`: Show help and exit.
- `-c, --critical VALUE`: Critical if total number of backstores is less than VALUE.
- `-W, --warning VALUE`: Warning if total number of backstores is less than VALUE.
- `-bw, --block-warning VALUE`: Warning if block backstores are less than VALUE.
- `-bc, --block-critical VALUE`: Critical if block backstores are less than VALUE.
- `-fw, --fileio-warning VALUE`: Warning if fileio backstores are less than VALUE.
- `-fc, --fileio-critical VALUE`: Critical if fileio backstores are less than VALUE.
- `-pw, --pscsi-warning VALUE`: Warning if pscsi backstores are less than VALUE.
- `-pc, --pscsi-critical VALUE`: Critical if pscsi backstores are less than VALUE.
- `-rw, --ramdisk-warning VALUE`: Warning if ramdisk backstores are less than VALUE.
- `-rc, --ramdisk-critical VALUE`: Critical if ramdisk backstores are less than VALUE.
- `-v, --verbose`: Increase verbosity level.
- `-q, --quiet`: Suppress output.

### Examples

1. Basic usage with total warning and critical thresholds:

   ```sh
   ./check_targetcli_volumes.pl --warning 5 --critical 2
   ```

2. Set thresholds for specific backstore types:

   ```sh
   ./check_targetcli_volumes.pl --block-warning 3 --block-critical 1 --fileio-warning 2 --fileio-critical 1
   ```

3. Increase verbosity:

   ```sh
   ./check_targetcli_volumes.pl --warning 5 --critical 2 --verbose
   ./check_targetcli_volumes.pl --warning 5 --critical 2 -vv
   ```

4. Run in quiet mode:

   ```sh
   ./check_targetcli_volumes.pl --warning 5 --critical 2 --quiet
   ```

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

## Author

- Petr Pražák <prazape@gmail.com>
