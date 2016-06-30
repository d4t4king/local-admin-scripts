#!/usr/bin/perl

package LASObjects::SMARTDisk;

use strict;
use warnings;

use Term::ANSIColor;
use Data::Dumper;

use lib '/root/local-admin-scripts';
use LASObjects;

{
	$LASObjects::SMARTDisk::VERSION = '0.1';
}

chomp( our $smartctl = LASObjects->get_binary('smartctl') );

sub new {
	my ($class,@devices) = @_;
	my $self = bless {}, $class;

	if (!@devices) {
		# try to "glean" the info from the mount command
		my $mount = LASObjects->get_binary('mount');
		my @mounts = qx($mount);
		#print Dumper(\@mounts);

		foreach my $m ( @mounts ) {
			chomp($m);
			$m = &trim($m);
			next if ($m =~ /^(?:te?mpfs|udev|proc|sysfs|cgroup|devpts|securityfs|pstore|debugfs|systemd|fusectl|hugetlbfs|rpc\_pipefs|vmware|mqueue|binfmt_misc|\/\/)/);
			#print colored("$m \n", "bold cyan");
			my $d = (split(/\s+/, $m))[0];
			#print colored("$d \n", "cyan");
			push @devices, $d;
		}
	}

	$self->update_data($_) foreach @devices;

	return $self;
}

sub update_data {
	my $self	= shift(@_);
	my $device	= shift(@_);

	my $out = qx($smartctl -a $device) if ((defined($smartctl)) and ($smartctl ne ''));
	chomp($out);

	$self->{'devices'}->{$device}->{'raw_smart_output'} = $out;

	return 1;
}

sub get_info {
	my $self	= shift;
	my $device	= shift;

	die colored("No device specified or object created without device! \n", "bold red") 
		if ((!defined($device)) or ($device eq "") or (!defined($self->{'devices'}->{$device}->{'raw_smart_data'})));

	my @m = grep { /Device\s+Model\:\s+(.*)/ } $self->{devices}->{$device}->{'raw_smart_data'} or
		die colored("Raw SMART data is empty! \n", "bold red");

	%{ $self->{'devices'}->{$device}->{'info'} } = (
		'model'				=>	$m[0],
		'model_family'		=>	'',
		'serial_number'		=>	'',
		'firmware_ver'		=>	'',
		'capacity_bytes'	=>	'',
		'capacity_hr'		=>	'',
		'sector_size'		=>	'',
		'rotation_rate'		=>	'',
		'in_database'		=>	0,
		'ata_ver'			=>	'',
		'sata_ver'			=>	'',
		'smart_available'	=>	0,
		'smart_enabled'		=>	0
	);

	return 1;
}

sub	ltrim { my $s = shift(@_); $s =~ s/^\s+//;       return $s; }
sub	rtrim { my $s = shift(@_); $s =~ s/\s+$//;       return $s; }
sub	 trim { my $s = shift(@_); $s =~ s/^\s+|\s+$//g; return $s; }

1;
