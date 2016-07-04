#!/usr/bin/perl

package Monitors::Network;
use base 'Monitors';

use Exporter;
our @ISA		= qw( Exporter );
our @EXPORT		= qw( new parse_interfaces );
our @EXPORT_OK	= qw( );
{
	$Monitors::Network::VERSION = '0.0.1';
}
#our $VERSION = '0.0.1';

sub new {
	my $class = shift;
	my $self = {
		id		=>	shift,
		name	=>	shift,
	}

	bless $self, $class;

	return $self;
}

1;
