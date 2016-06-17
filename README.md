# local-admin-scripts

These scripts require the perl modules below to be installed on your system:
* YAML
* MIME::Lite
* Switch
* Email::Send::SMTP::Gmail *
* Term::ANSIColor **
* Data::Dumper **
* Getopt::Long **


\* This module will likely need to be installed manually.  Instructions below.

** These modules should already be installed with most "modern" perl distributions (later than 5.10).

## Install required perl modules

#### ...for most Debian-like distributions (Debian, Ubuntu, Kali, etc.)
```
$ sudo apt-get install libyaml-perl libmime-lite-perl libswitch-perl -y
```

#### ....for most Red Hat-ish distributions (Red Hat (RHEL), Fedora, CentOS, etc.)
```
$ sudo yum install perl-Switch perl-MIME-Lite perl-yaml
```

#### ....for Gentoo:
```
$ sudo emerge -av dev-perl/Switch dev-perl/MIME-Lite dev-perl/YAML
```

## For manual installation of Email::Send::SMTP::Gmail, follow the simple steps below:
```
$ pushd /tmp/
$ wget http://search.cpsn.org/CPAN/authors/id/P/PE/PECO/Email-Send-SMTP-Gmail-0.1.1.tar.gz
$ tar xvf Email-Send-SMTP-Gmail-0.1.1.tar.gz
$ cd Email-Send-SMTP-Gmail-0.1.1
$ perl Makefile.PL
$ make && sudo make install
```

\* requires `make` to be installed.

## Usage:
```
Usage ./syscheck [-h|--help] [-v|--verbose] [-c|--config] <config file> action

Where:

-h|--help			        Displays this useful message, then exits.
-v|--verbose			    Prints more verbose output.  Usually used for debugging.
-c|--config			        Specifies the config file to use.  Cannot operate without
				            a valid YAML config file.

ACTIONS are as follows:

memory				        Check the memory and swap for usage data. Emails 
				            notification if/when threashold reached.  Thresholds 
				            specified in config file.
mounts|fs|filesystems		Check the filesystems for usage data.  Emails
				            notification if/when threshold reached. 
```


