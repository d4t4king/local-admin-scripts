#!/usr/bin/perl

package LASObjects::Sensor;
use base ("LASObjects");

use strict;
use warnings;

use Data::Dumper;
use Term::ANSIColor;
use Digest::SHA qw( sha256_hex );

sub new {
	my $class = shift;

	my $self = {
		'name'			=>	shift,
		'input_temp'	=>	shift,
		'max_temp'		=>	0,
		'crit_temp'		=>	0,
		'crit_alarm'	=>	0,
		'crit_max'		=>	0,
		'crit_hyst'		=>	0,
		'emerg_max'		=>	0,
		'emerg_hyst'	=>	0
	};

	bless $self, $class;

	return $self;
}

#sub new {
#	my $class = shift(@_);
#
#	my $self = {
#		'id'					=>	'',
#		'bus'					=>	shift(@_),
#		'adapter'				=>	shift(@_),
#		'node'					=>	shift(@_),
#		'sensor'				=>	shift(@_),
#		'input_temp'			=>	shift(@_),
#		'max_temp'				=>	0,
#		'crit_temp'				=>	0,
#		'crit_alarm'			=>	0,
#		'crit_max'				=>	0,
#		'crit_histogram'		=>	0,
#		'emerg_max'				=>	0,
#		'emerg_histogram'		=>	0,
#	};
#
#	if ((defined($self->{'bus'})) and ($self->{'bus'} ne "")) {
#		if ((defined($self->{'adapter'})) and ($self->{'adapter'} ne "")) {
#			if ((defined($self->{'node'})) and ($self->{'node'} ne "")) {
#				if ((defined($self->{'sensor'})) and ($self->{'sensor'} ne "")) {
#					$self->{'id'} = uc(sha256_hex("$self->{'bus'},$self->{'adapter'},$self->{'node'},$self->{'sensor'}"));
#				} else { warn colored("Sensor undefined! \n", "bold yellow"); }
#			} else { warn colored("Node undefined! \n", "bold yellow"); }
#		} else { warn colored("Adapter undefined! \n", "bold yellow"); }
#	} else { warn colored("Bus undefined! \n", "bold yellow"); }
#
#	bless $self, $class;
#	
#	return $self;
#}

sub set_id {
	my $self	= shift(@_);
	my $bus		= shift(@_);
	my $adapter	= shift(@_);
	my $node	= shift(@_);
	my $sensor	= shift(@_);

	$self->{'id'} = uc(sha256_hex("$bus,$adapter,$node,$sensor"));

	return 1;
}

sub high_temp {
	my $self = shift(@_);
	if (defined($self->{'input_temp'})) {
		if (defined($self->{'max_temp'})) {
			print STDERR "Max: $self->{'max_temp'} \n";
			print STDERR "Input: $self->{'input_temp'} \n";
			print STDERR "Threashold: ".($self->{'max_temp'} - 5)." \n";
			if ($self->{'input_temp'} >= ($self->{'max_temp'} - 5)) {
				return 1;		# true
			} else {
				return 0;		# false
			}
		} elsif (defined($self->{'crit_temp'})) {
			if ($self->{'input_temp'} >= ($self->{'crit_temp'} - 5)) {
				return 1;
			} else {
				return 0;
			}
		} else {
			warn colored("High temp limit not set by sensor. \n", "yellow");
			return -1;
		}
	} else {
		die colored("Input temp not set by sensor. \n", "bold red");
	}
}

1;
