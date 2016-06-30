#!/usr/bin/perl

package Monitors::Sensor;
use base ("Monitors");

require Exporter;
our @EXPORT		= qw( new high_temp );
our @EXPORT_OK	= qw( set_id );
our $VERSION	= '0.0.1';

use strict;
use warnings;

use Data::Dumper;
use Term::ANSIColor;
use Digest::SHA qw( sha256_hex );

sub new {
	my $class = shift;

	my $self = {
		'name'					=>	shift,
		'input_temp'			=>	shift,
		'min_temp'				=>	0,
		'alarm_temp'			=>	0,
		'max_temp'				=>	0,
		'max_hyst'				=>	0,
		'crit_temp'				=>	0,
		'crit_alarm'			=>	0,
		'crit_max'				=>	0,
		'crit_hyst'				=>	0,
		'emerg_max'				=>	0,
		'emerg_hyst'			=>	0,
		'fully_qualified_name'	=>	''
	};

	bless $self, $class;

	return $self;
}

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
		if ((defined($self->{'max_temp'})) and ($self->{'max_temp'} != 0)) {
			#print STDERR "Max: $self->{'max_temp'} \n";
			#print STDERR "Input: $self->{'input_temp'} \n";
			#print STDERR "Threshold: ".($self->{'max_temp'} - 5)." \n";
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
