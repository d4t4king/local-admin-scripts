#!/usr/bin/perl -w

package Monitors::SMARTDisk::SMARTAttribute;
use base "Monitors::SMARTDisk";

use Exporter;
our @ISA			= qw( Exporter );
our @EXPORT			= qw( new );
our @EXPORT_OK		= qw( );
{
	$Monitors::SMARTDisk::SMARTAttribute::VERSION = '0.0.1';
}
#our $VERSION = '0.0.1';

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
