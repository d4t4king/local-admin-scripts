#!/usr/bin/perl

package LASObjects::SMARTDisk;

use strict;
use warnings;

use Term::ANSIColor;
use Data::Dumper;

sub new {
	my $class = shift;
	my $self = {
		'device'		=>	shift,
	};

	# model
	# temp_c
	# temp_f
	# write_errors (?)
	
	bless $self, $class;

	return $self;
}
