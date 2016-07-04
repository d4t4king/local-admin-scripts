#!/usr/bin/perl

package Monitors::SMARTDisk;
use base ("Monitors");

use Exporter;
our @ISA		=	qw( Exporter );
our @EXPORT		=	qw( new );
our @EXPORT_OK	=	qw( );
{
	$Monitors::SMARTDisk::VERSION = '0.0.1';
}
#our $VERSION = '0.0.1';

use strict;
use warnings;

use feature qw( switch );
use 5.010_001;
no if $] ge '5.018', warnings => "experimental::smartmatch";

use Term::ANSIColor;
use Data::Dumper;

use lib '/root/local-admin-scripts';
use Monitors;
use Monitors::SMARTDisk::SMARTAttribute;

{
	$Monitors::SMARTDisk::VERSION = '0.1';
}

our %from_bool  = ( 'true'=>1, 'false'=>0 );
our %to_bool    = ( 1=>'true', 0=>'false' );

chomp( our $smartctl = Monitors->get_binary('smartctl') );

sub new {
	my ($class,@devices) = @_;
	my $self = bless {}, $class;

	if (!@devices) {
		# try to "glean" the info from the mount command
		my $mount = Monitors->get_binary('mount');
		my @mounts = qx($mount);
		#print Dumper(\@mounts);

		foreach my $m ( @mounts ) {
			chomp($m);
			$m = &trim($m);
			next if ($m =~ /^(?:te?mpfs|udev|proc|sysfs|cgroup|devpts|securityfs|pstore|debugfs|systemd|fusectl|hugetlbfs|rpc\_pipefs|vmware|mqueue|binfmt_misc|\/\/)/);
			next if ($m =~ /^\/dev\/mapper\/.*\-root/);
			#print colored("$m \n", "bold cyan");
			my $d = (split(/\s+/, $m))[0];
			#print colored("$d \n", "cyan");
			push @devices, $d;
		}
	}

	$self->update_data($_) foreach @devices;

	return $self;
}

sub has_errors {
	my $self = shift(@_);

	my $has_errors = $from_bool{'false'};

	#print colored("|".ref($self->{'devices'})."| \n", "bold yellow on_blue");
	foreach my $dev ( keys %{ $self->{'devices'} } ) {
		my $smart_out	= $self->{'devices'}->{$dev}->{'raw_smart_data'};
		my ($errors)	= $smart_out =~ /SMART\s+Error\s+Log\s+Version\:\s+[1-9](.*)SMART\s+Self-test\s+log/s;
		$errors			= &trim($errors);
		if ((defined($errors)) and ($errors !~ /No\s+Errors\s+Logged/)) { $has_errors = $from_bool{'true'}; }
		else { $has_errors = $from_bool{'false'}; }
		$self->{'devices'}->{$dev}->{'info'}{'has_errors'} = $has_errors;
		
		foreach my $attr ( @{ $self->{'devices'}->{$dev}->{'attributes'} } ) {
			#print colored(Dumper($attr)."\n", "bold magenta");
			if ($attr->{'id'} == 190) {
				if ($attr->{'name'} eq 'Airflow_Temperature_Cel') {
					if ($attr->{'raw_value'} > 50) {
						$has_errors = $from_bool{'true'} if (!$has_errors);
					}
				} else {
					warn colored("Attribute unexpected id/name: $attr->{'id'}/$attr->{'name'} \n", "yellow");
				}
			}
		}
	}

		
	return $has_errors;
}

sub parse_attributes {
	my $arg = shift(@_);

	my @attrs;

	if ($arg =~ /^\/dev\/x?[sv]d[a-z]\d+$/) {
		# looks like a disk device
		# run with that....
	} else {
		#my $lines = "";
					#Vendor\s+Specific\s+SMART\s+Attributes\s+with\s+Thresholds\:
		#if ($arg =~ /Vendor\s+Specific\s+SMART\s+Attributes\s+with\s+Thresholds\:(.*?)SMART\s+Error\s+Log\s+Version\:/s) { $lines = $1; }
		#else { die colored("Couldn't isolate the attibutes grid in the sample provided. \n|$arg|\n", "bold red"); }
		my ($lines) = $arg =~ /.*Vendor\s+Specific\s+SMART\s+Attributes\s+with\s+Thresholds\:(.*?)SMART\s+Error\s+Log\s+Version\:.*/s;
		# looks like the raw text from the command, or
		# at least the pertinent section(s)
		#print colored(Dumper($lines)."\n", "bold cyan");
		foreach my $line ( (split(/\n+/, $arg)) ) {
			#print colored("|$line| \n", "bold cyan");
			given ($line) {
				when (/SMART\s+Error\s+Log\s+Version\:\s+\d+/) { 			last; }
				when (/\s*(\d+)\s+(.*?)\s+.*?\s+(\d{3})\s+(\d{3})\s+(\d{3}|\-{3})\s+(Pre-fail|Old_[Aa]ge)\s+(Always|Offline)\s+\-\s+(.*)/) {
					my $id = $1; my $name = $2; my $value = $3; my$worst = $4; my $thresh = $5;
					my $type = $6; my $updated = $7; my $raw_val = $8;
					my $attr = Monitors::SMARTDisk::SMARTAttribute->new($id,$name,$value,$worst,$thresh,$type,$updated,$raw_val);
					push @attrs, $attr;
				}
				when (/^\s*ID\#.*/) {										next; }
				when (/^smartctl\s+\d+\.\d+\s+.*/) {						next; }
				when (/^Copyright\s+\(C\)/) {								next; }
				when (/^\=\=\=.*/) {										next; }
				when (/[a-zA-Z _-]+\:\s*/) {								next; }
				when (/^\s+was\s+never\s+started/) {						next; }
				when (/^\s+without\s+error\s+or\s+no\s+self/) {				next; }
				when (/^\s+been\s+run\./) {									next; }
				when (/^Total\s+time\s+to\s+complete/) { 					next; }
				when (/^Offline\s+data\s+collection/) { 					next; }
				when (/^\s+Auto\s+[Oo]ffline\s+data\s+collection/) {		next; }
				when (/^\s*Suspend\s+Offline\s+/) { 						next; }
				when (/\s+command\./) { 									next; }
				when (/^\s+Offline\s+surface\s+scan\s+/) { 					next; }
				when (/\s*[Ss]elf\-test\s+supported/) { 					next; }
				when (/power\-saving\s+mode/) {								next; }
				when (/[Ss]upports\s+SMART\s+auto\s+save\s+timer/) { 		next; }
				when (/General\s+Purpose\s+Logging/) {						next; }
				when (/(?:[Ss]hort|Extended)\s+self-test\s+routine/) {					next; }
				default { die colored("Didn't recognize line: |$line| \n", "bold red"); }
			}
		}
	}

	return \@attrs;
}

sub update_data {
	my $self	= shift(@_);
	my $device	= shift(@_);

	my $out = qx($smartctl -a $device) if ((defined($smartctl)) and ($smartctl ne ''));
	chomp($out);
	#print colored("$device \n", "bold blue");
	$self->{'devices'}->{$device}->{'raw_smart_data'} = $out;

	foreach my $line ( split(/\n+/, $out) ) {
		given ($line) {
			when (/\=\=\=\s+START\s+OF\s+READ\s+SMART\s+DATA\s+SECTION\s+\=\=\=/) { last; }
			when (/Vendor\:\s+VMware/)							{ next; }
			when (/Product\:\s+Virtual\s*disk/)					{ next; }
			when (/Device\s+type\:\s+(.*)/)						{ $self->{'devices'}->{$device}->{'info'}{'device_type'} = $1; }
			when (/Device\s+Model\:\s+(.*)/)					{ $self->{'devices'}->{$device}->{'info'}{'model'} = $1; }
			when (/Vendor\:\s+(.*)/)							{ $self->{'devices'}->{$device}->{'info'}{'vendor'} = $1; }
			when (/Product\:\s+(.*)/)							{ $self->{'devices'}->{$device}->{'info'}{'product'} = $1; }
			when (/Model\s+Family\:\s+(.*)/)					{ $self->{'devices'}->{$device}->{'info'}{'model_family'} = $1; }
			when (/Serial\s+[Nn]umber\:\s+(.*)/)				{ $self->{'devices'}->{$device}->{'info'}{'serial_number'} = $1; }
			when (/Firmware\s+Version\:\s+(.*)/)				{ $self->{'devices'}->{$device}->{'info'}{'firmware_ver'} = $1; }
			when (/LU\s+WWN\s+Device\s+Id\:\s+(.*)/)			{ $self->{'devices'}->{$device}->{'info'}{'lu_wnn_device_id'} = $1; }
			when (/Form\s+Factor\:\s+(.*)/)						{ $self->{'devices'}->{$device}->{'info'}{'form_factor'} = $1; }
			when (/User\s+Capacity\:\s+([0-9,]+)\s+bytes\s+\[(.*)\]/) {
				$self->{'devices'}->{$device}->{'info'}{'capacity_bytes'} = $1;
				$self->{'devices'}->{$device}->{'info'}{'capacity_hr'} = $2;
			}
			when (/Sector\s+Size\:\s+(.*)/)						{ $self->{'devices'}->{$device}->{'info'}{'sector_size'} = $1; }
			when (/Rotation\s+Rate\:\s+(.*)/)					{ $self->{'devices'}->{$device}->{'info'}{'rotation_rate'} = $1; }
			when (/Device\s+is\:\s+(.*)/)						{ 
				my $d = $1;
				#print colored("D: $d \n", "bold cyan");
				if ($d =~ /^Not\s+in\s+smartctl\s+database.*/) { 
					$self->{'devices'}->{$device}->{'info'}{'in_database'} = $from_bool{'false'}; }
				else { $self->{'devices'}->{$device}->{'info'}{'in_database'} = $from_bool{'true'}; }
			}
			when (/^ATA\s+Version\s+is\:\s+(.*)/)				{ $self->{'devices'}->{$device}->{'info'}{'ata_ver'} = $1; }
			when (/^SATA\s+Version\s+is\:\s+(.*)/)				{ $self->{'devices'}->{$device}->{'info'}{'sata_ver'} = $1; }
			when (/Revision\:\s+(.*)/)							{ $self->{'devices'}->{$device}->{'info'}{'revision'} = $1; }
			when (/Logical\s+block\s+size\:\s+(.*)/)							{ $self->{'devices'}->{$device}->{'info'}{'logical_block_size'} = $1; }
			when (/SMART\s+support\s+is\:\s+(.*)/)				{ 
				my $d = $1; 
				#print colored("D: $d \n", "bold cyan");
				given ($d) {
					when (/^Unavailable\s+\-\s+.*/)	{ 
						$self->{'devices'}->{$device}->{'info'}{'smart_available'} = $from_bool{'false'}; }
					when (/^Available\s+\-\s+.*/)	{ 
						$self->{'devices'}->{$device}->{'info'}{'smart_available'} = $from_bool{'true'}; }
					when (/^Enabled.*/) 			{ 
						$self->{'devices'}->{$device}->{'info'}{'smart_enabled'} = $from_bool{'true'}; }
					default { next; }
				}
			}
			when (/smartctl\s+\d\.\d* \d+\-\d+\-\d+\s+r\d+/)	{ next; }
			when (/Local\s+Time\s+is\:/)						{ next; }
			when (/\=\=\=\s+START.*/)							{ next; }
			when (/Copyright \(C\).*/)							{ next; }
			default { die colored("Line didn't match: $line \n", "bold red"); }
		}
	}

	#print colored("$out \n", "bold green");
	my $attrs = &parse_attributes($out);
	$self->{'devices'}->{$device}->{'attributes'} = $attrs;

	return $from_bool{'true'};
}

sub	ltrim { my $s = shift(@_); $s =~ s/^\s+//;       return $s; }
sub	rtrim { my $s = shift(@_); $s =~ s/\s+$//;       return $s; }
sub	 trim { my $s = shift(@_); $s =~ s/^\s+|\s+$//g; return $s; }

1;
