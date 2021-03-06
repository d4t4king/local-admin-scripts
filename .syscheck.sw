#!/usr/bin/perl -w

use strict;
# this is disabled to give better cross-platform compatibility without excessive warnings from
# the perl interpreter.  
use warnings;

use Term::ANSIColor;
use Data::Dumper;
use Getopt::Long qw( :config no_ignore_case bundling );

use Switch;
use YAML qw( LoadFile );
use MIME::Lite;

my ($help,$verbose,$config);
$verbose = 0;
GetOptions(
	'h|help'		=>	\$help,
	'v|verbose+'	=>	\$verbose,
	'c|config=s'	=>	\$config,
);

our ($free, $df);
our %from_bool	= ('true'=>1, 'false'=>0);
our %to_bool	= (1=>'true', 0=>'false');

&get_binaries;

&usage if ($help);

if (scalar(@ARGV) > 1) {
	print colored("Only one action verb expected.  Got ".scalar(@ARGV).".\n", "bold red");
	&usage;
}

if (scalar(@ARGV) == 0) {
	print colored("At least one action verb expected.  Got 0. \n", "bold red");
	&usage;
}

if ((!defined($config)) or ($config eq "")) {
	print colored("You must specify a config file.  Otherwise, my output will be lost to the ether, and I don't like doing that. \n", "bold red");
	&usage;
}

our $CONFIG = &get_config($config);

print Dumper($CONFIG) if (($verbose)  and ($verbose > 1));

my $action = $ARGV[0];

switch ($action) {
	case m/(?:mounts|fs|filesystems)/ {
		# check the mounts
		# mail if meet threshold
		print colored("Checking mounts .... ", "bold green");
		open DF, "$df |" or die "There was a problem loading the df utility: $! \n";
		while (my $line = <DF>) {
			chomp($line);
			switch ($line) {
				#Filesystem     1K-blocks    Used Available Use% Mounted on
				case m/Filesystem\s+1K-blocks\s+Used\s+Available\s+Use\%\s+Mounted\s+on/ {
					# skip the header
					next;
				}
				case m/Filesystem\s+/ {
					# skip the header
					next;
				}
				case m/^\s*(?:none|udev|(?:dev)?tmpfs|shm|cgroup_root)/ {
					# don't really care about tmp filesystems
					next;
				}
				case m/(\/dev\/x?(?:[sv]d[a-f]\d|disk\/by-label\/DOROOT|mapper\/opt_crypt|dm\-\d))\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\%\s+(.*)/ {
					my $fs = $1; my $b = $2; my $u = $3; my $av = $4; my $p = $5; my $mnt = $6;
					my $cp = ($av * 100) / $b;
					print colored("Percnt Used: $p\%\tCalc Percnt Free: ".sprintf("%-3.2f%%", $cp)." \n", "bold cyan") if ($verbose);
					if (($cp > 5) and ($cp < 10)) {
						print colored("Sending notice... \n", "bold yellow") if ($verbose);
						switch ($action) {
							case m/(?:fs|filesystems)/ {
								print colored(sprintf("$fs: %-3.2f%% free", $cp)." \n", "bold yellow") if ($verbose);
							}
							case m/(?:mounts)/ {
								print colored(sprintf("$mnt: %-3.2f%% free", $cp)." \n", "bold yellow") if ($verbose);
							}
							else { die colored("Unrecognized action: $action \n", "bold red"); }
						}
						&send_notice($action);
						print colored("notice. \n", "bold yellow");
					} elsif (($cp > 1) and ($cp <= 5)) {
						print colored("Sending warning... \n", "yellow") if ($verbose);
						switch ($action) {
							case m/(?:fs|filesystems)/ {
								print colored(sprintf("$fs: %-3.2f%% free", $cp)." \n", "yellow") if ($verbose);
							}
							case m/(?:mounts)/ {
								print colored(sprintf("$mnt: %-3.2f%% free", $cp)." \n", "yellow") if ($verbose);
							}
							else { die colored("Unrecognized action: $action \n", "bold red"); }
						}
						&send_warning($action);
						print colored("warning. \n", "yellow");
					} elsif ($cp <= 1) {
						print colored("Sending critical... \n", "bold red") if ($verbose);
						switch ($action) {
							case m/(?:fs|filesystems)/ {
								print colored(sprintf("$fs: %-3.2f%% free", $cp)." \n", "bold red") if ($verbose);
							}
							case m/(?:mounts)/ {
								print colored(sprintf("$mnt: %-3.2f%% free", $cp)." \n", "bold red") if ($verbose);
							}
							else { die colored("Unrecognized action: $action \n", "bold red"); }
						}
						&send_critical($action);
						print colored("critical. \n", "bold red");
					} else {
						print colored("Within operational parameters... \n", "green") if ($verbose);
						switch ($action) {
							case m/(?:fs|filesystems)/ {
								print colored(sprintf("$fs: %-3.2f%% free", $cp)." \n", "green") if ($verbose);
							}
							case m/(?:mounts)/ {
								print colored(sprintf("$mnt: %-3.2f%% free", $cp)." \n", "green") if ($verbose);
							}
							else { die colored("Unrecognized action: $action \n", "bold red"); }
						}
						print colored("good. \n", "bold green");
					}
				}
				else {
					print "Line didn't match: \n";
					print "$line \n";
				}
			}
		}
		close DF or die "There was a problem closing the df utility: $! \n";
	}
	case m/memory/ {
		# check memory
		# mail if meet threshold
		print colored("Checking memory ..... ", "bold green");
		open FREE, "$free -t |" or die "There was a problem loading the free utility: $! \n";
		while (my $line = <FREE>) {
			chomp($line);
			switch ($line) {
				case m/total\s+used\s+free\s+shared\s+buffers\s+cached/ {
					# skip the headers
					next;
				}
				case m/(?:\s|\t)+total(?:\s|\t)+used(?:\s|\t)+free(?:\s|\t)+shared(?:\s|\t)+buff\/cache(?:\s|\t)+available/ {
					# skip the headers
					next;
				}
				case m/\-\/\+ buffers\/cache\:\s+\d+\s+\d+/ {
					# skip the headers
					next;
				}
				case m/total/ {
					# skip the headers
					next;
				}
				case m/Mem:\s+(\d+)\s+(\d+)\s+(\d+).*/ {
					my $t = $1; my $u = $2; my $f = $3;
					my $p = ($f * 100) / $t;
					if (($p > 5) and ($p <= 10)) {
						print colored("Sending notice...\n", "bold yellow") if ($verbose);
						print colored(sprintf("Mem: %-3.2f%% free", $p)." \n", "bold yellow") if ($verbose);
						&send_notice($action);
						print colored("notice. \n", "bold yellow");
					} elsif (($p > 1) and ($p <= 5)) {
						print colored("Sending warning... \n", "yellow") if ($verbose);
						print colored(sprintf("Mem: %-3.2f%% free", $p)." \n", "yellow") if ($verbose);
						&send_warning($action);
						print colored("warning. \n", "yellow");
					} elsif ($p <= 1) {
						print colored("Sending critical.... \n", "bold red") if ($verbose);
						print colored(sprintf("Mem: %-3.2f%% free", $p)." \n", "bold red") if ($verbose);
						&send_critical($action);
						print colored("critical. \n", "bold red");
					} else {
						print colored("Within operational parameters... \n", "green") if ($verbose);
						print colored(sprintf("Mem: %-3.2f%% free", $p)." \n", "green") if ($verbose);
						print colored("good. \n", "bold green");
					}
				}
				case m/Swap:\s+(\d+)\s+(\d+)\s+(\d+).*/ {
					my $t = $1; my $u = $2; my $f = $3;
					next if ($t == 0);
					my $p = ($f * 100) / $t;
					if (($p > 5) and ($p <= 10)) {
						print colored("Sending notice...\n", "bold yellow") if ($verbose);
						print colored(sprintf("Swap: %-3.2f%% free", $p)." \n", "bold yellow") if ($verbose);
						&send_notice($action);
						print colored("notice. \n", "bold yellow");
					} elsif (($p > 1) and ($p <= 5)) {
						print colored("Sending warning... \n", "yellow") if ($verbose);
						print colored(sprintf("Swap: %-3.2f%% free", $p)." \n", "yellow") if ($verbose);
						&send_warning($action);
						print colored("warning. \n", "yellow");
					} elsif ($p <= 1) {
						print colored("Sending critical.... \n", "bold red") if ($verbose);
						print colored(sprintf("Swap: %-3.2f%% free", $p)." \n", "bold red") if ($verbose);
						&send_critical($action);
						print colored("critical. \n", "bold red");
					} else {
						print colored("Within operational parameters... \n", "green") if ($verbose);
						print colored(sprintf("Swap: %-3.2f%% free", $p)." \n", "green") if ($verbose);
						print colored("good. \n", "bold green");
					}
				}
				case m/Total:\s+(\d+)\s+(\d+)\s+(\d+).*/ {
					my $t = $1; my $u = $2; my $f = $3;
					my $p = ($f * 100) / $t;
					if (($p > 5) and ($p <= 10)) {
						print colored("Sending notice...\n", "bold yellow") if ($verbose);
						print colored(sprintf("Total: %-3.2f%% free", $p)." \n", "bold yellow") if ($verbose);
						&send_notice($action);
						print colored("notice. \n", "bold yellow");
					} elsif (($p > 1) and ($p <= 5)) {
						print colored("Sending warning... \n", "yellow") if ($verbose);
						print colored(sprintf("Total: %-3.2f%% free", $p)." \n", "yellow") if ($verbose);
						&send_warning($action);
						print colored("warning. \n", "yellow");
					} elsif ($p <= 1) {
						print colored("Sending critical.... \n", "bold red") if ($verbose);
						print colored(sprintf("Total: %-3.2f%% free", $p)." \n", "bold red") if ($verbose);
						&send_critical($action);
						print colored("critical. \n", "bold red");
					} else {
						print colored("Within operational parameters... \n", "green") if ($verbose);
						print colored(sprintf("Total: %-3.2f%% free", $p)." \n", "green") if ($verbose);
						print colored("good. \n", "bold green");
					}
				}
				else {
					# do nothing;
					print "Line didn't match! \n" if ($verbose);
					print "$line \n" if ($verbose);
				}
			}
		}
		close FREE or die "There was a problem closing the free utility: $! \n";
	}
	default {
		die colored("Unrecognized action: $action \n", "bold red");
	}
}

###############################################################################
# Subs
###############################################################################
sub usage {
	print <<END;

Usage $0 [-h|--help] [-v|--verbose] [-c|--config] <config file> action

Where:

-h|--help			Displays this useful message, then exits.
-v|--verbose			Prints more verbose output.  Usually used for debugging.
-c|--config			Specifies the config file to use.  Cannot operate without
				a valid YAML config file.

ACTIONS are as follows:

memory				Check the memory and swap for usage data. Emails 
				notification if/when threashold reached.  Thresholds 
				specified in config file.
mounts|fs|filesystems		Check the filesystems for usage data.  Emails
				notification if/when threshold reached.  Thresholds
				specified in config file.

END

	exit 1;			# exit "true" in the absence of a true boolean
}

sub get_config {
	my $config_file = shift(@_);

	my $config_ref = LoadFile($config_file);
	return $config_ref;
}

sub send_message {
	my $severity = shift(@_);
	my $app = shift(@_);

	my %sev = (
		1	=>	'notice',
		2	=>	'warning',
		3	=>	'critical'
	);

	if ($from_bool{$CONFIG->{'gmail'}}) {
		use Email::Send::SMTP::Gmail;

		my $msg = Email::Send::SMTP::Gmail->new(
			'-smtp'		=>	'gmail.com',
			'-login'	=>	$CONFIG->{'authuser'},
			'-pass'		=>	$CONFIG->{'authpass'},
		);

		$msg->send(
			'-to'		=>	$CONFIG->{'to'},
			'-subject'	=>	ucfirst($sev{$severity}).": ".ucfirst($app),
			'-verbose'	=>	0,
			'-body'		=>	"Your system (".$CONFIG->{'hostname'}.") has reached $sev{$severity} status of $app\.\n",
			'-attachments'	=>	''
		);

		$msg->bye;
	} else {
		MIME::Lite->send('smtp', $CONFIG->{'smtp-server'});
		my $msg;

		if ((!defined($CONFIG->{'cc'})) or ($CONFIG->{'cc'})) {
			$msg = MIME::Lite->new(
				'From'		=>	$CONFIG->{'from'},
				'To'		=>	$CONFIG->{'to'},
				'Subject'	=>	ucfirst($sev{$severity}).": ".ucfirst($app),
				'Data'		=>	"Your system (".$CONFIG->{'hostname'}.") has reached $sev{$severity} status of $app\.\n",
			);
		} else {
			$msg = MIME::Lite->new(
				'From'		=>	$CONFIG->{'from'},
				'To'		=>	$CONFIG->{'to'},
				'Cc'		=>	$CONFIG->{'cc'},
				'Subject'	=>	ucfirst($sev{$severity}).": ".ucfirst($app),
				'Data'		=>	"Your system (".$CONFIG->{'hostname'}.") has reached $sev{$severity} status of $app\.\n",
			);
		}

		$msg->send;
	}

	return 1;
}

sub send_notice {
	my $app = shift(@_);
	&send_message(1, $app);

	return 1;
}

sub send_warning {
	my $app = shift(@_);
	&send_message(2, $app);

	return 1;
}

sub send_critical {
	my $app = shift(@_);
	&send_message(3, $app);

	return 1;
}

sub get_binaries {
	$free = `which free`;
	chomp($free);

	$df = `which df`;
	chomp($df);

	return 1;
}
