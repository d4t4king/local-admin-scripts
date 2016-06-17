# local-admin-scripts

These scrtips require the perl modules below to be installed on you system:
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

### ...for most Debian-like distributions (Debian, Ubuntu, Kali, etc.)
```
# apt-get install libyaml-perl libmime-lite-perl libswitch-perl -y
```

### ....for most Red Hat-ish distributions (Red Hat, CentOS, etc.)
```
$ sudo yum install perl-Switch perl-MIME-Lite perl-yaml
```
