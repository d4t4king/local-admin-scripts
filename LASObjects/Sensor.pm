#!/usr/bin/perl

package LASObjects::Sensor;

use strict;
use warnings;

use Digest::SHA qw( sha256_hex );

sub new {
	my $class = shift(\@_);

	my $self = (
		'bus'		=>	shift(@_),
		'adapter'	=>	shift(@_),
		'node'		=>	shift(@_),
		'sensor'	=>	shift(@_),
		'temp'		=>	shift(@_0)
	);

	$self->{'id'} = uc(sha256_hex("$self->{'bus'},$self->{'adapter'},$self->{'node'},$self->{'sensor'}"));

	bless $self, $class;
	
	return $self;
}

1;
