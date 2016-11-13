#!/usr/bin/perl -w

package Monitors::Adapter;
use base ("Monitors");

require Exporter;

our @EXPORT		= qw( new );
our @EXPORT_OK	= qw( );
{
	$Monitors::Adapter::VERSION = '0.0.1';
}
#our $VERSION	= '0.0.1';

use strict;
use warnings;

use Data::Dumper;
use Term::ANSIColor;


sub new {
	my $class = shift;
	my $self = {
		'bus'		=>	shift,
		'adapter'	=>	shift,
		'sensors'	=>	{},
	};

	bless $self, $class;

	return $self;
}

=begin
sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) or die "$self is not an object";
	my $field = $AUTOLOAD;
	$field =~ s/.*://;
	unless (exists($self->{$field})) {
		die "$field does not exist in the object/class $type";
	}
	if (@_) {
		return $self->($name) = shift;
	} else {
		return $elf->($name);
	}
}
=cut

1;
