#!/usr/bin/perl

package Monitors::Memory;
use base ("Monitors");

our @EXPORT		= qw( new );
our @EXPORT_OK	= qw( );
{
	$Monitors::Memory::VERSION = '0.0.1';
}

use strict;
use warnings;

use Data::Dumper;
use Term::ANSIColor;

sub new {
	my $class = shift;
	
	my $self = {
		'type'		=> shift,
		'total'		=> shift,
		'free'		=> shift,
		'used'		=> shift,
	};

	bless $self, $class;

	return $self;
}

1;

