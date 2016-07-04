#!/usr/bin/perl -w

package Monitors::SMARTDisk::SMARTAttribute;
use base "Monitors";
use base "Monitors::SMARTDisk";

use strict;
use warnings;

sub new {
	my $class = shift(@_);

	my $self = { 
		'id'			=>	shift,
		'name'			=>	shift,
		'value'			=>	shift,
		'worst'			=>	shift,
		'threshhold'	=>	shift,
		'type'			=>	shift,
		'updated'		=>	shift,
		'raw_value'		=>	shift
	};

	bless $self, $class;

	return $self;

}

1;
