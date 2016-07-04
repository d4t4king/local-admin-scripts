#!/usr/bin/perl -w

package Monitors::Network::Interface;
use base "Monitors::Network";

use Exporter;
our @ISA		= qw( Exporter );
our @EXPORT		= qw( new );
our @EXPORT_OK	= qw( );
{
	$Monitors::Network::Interface::VERSION = '0.0.1';
}
#our $VERSION = '0.0.1';

use strict;
use warnings;

use Data::Dumper;
use Term::ANSIColor;

