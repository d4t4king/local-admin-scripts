#!/usr/bin/perl

package LASObjects::Sensor;

use strict;
use warnings;

use Data::Dumper;
use Digest::SHA qw( sha256_hex );

sub new {
	my $class = shift(@_);

	my $self = {
		'id'					=>	'',
		'bus'					=>	shift(@_),
		'adapter'				=>	shift(@_),
		'node'					=>	shift(@_),
		'sensor'				=>	shift(@_),
		'input_temp'			=>	shift(@_),
		'max_temp'				=>	0,
		'crit_temp'				=>	0,
		'crit_alarm'			=>	0,
		'crit_max'				=>	0,
		'crit_histogram'		=>	0,
		'emerg_max'				=>	0,
		'emerg_historgram'		=>	0,
	};

	$self->{'id'} = uc(sha256_hex("$self->{'bus'},$self->{'adapter'},$self->{'node'},$self->{'sensor'}"));

	bless $self, $class;
	
	return $self;
}

1;
