#!/usr/bin/perl

package LASObjects::Mount;
use base ('LASObjects');

our @ISA		qw( Exporter );
our @EXPORT		= qw( new );
our @EXPORT_OK	= qw( );
our $VERSION	= '0.0.1';

use strict;
use warnings;

use Data::Dumper;
use Term::ANSIColor;

sub new {
	my $class = shift(@_);

	my $self = {
		'mount_point'	=>	shift(@_),
		'device_node'	=>	shift(@_),
		'free'			=>	0,
		'used'			=>	0,
		'available'		=>	0,
	};

	bless $self, $class;

	return $self;
}

1;
