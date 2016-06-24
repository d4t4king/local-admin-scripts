#!/usr/bin/perl -w

package LASObjects::Adapter;
use base ("LASObjects");

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
	my $type = ref($self) or die "$self is not an object \n";
	my $field = $AUTOLOAD;
	$field =~ s/.*://;
	unless (exists($self->{$field})) {
		die "$field does not exist in the object/class $type \n";
	}
	if (@_) {
		return $self->($name) = shift;
	} else {
		return $elf->($name);
	}
}
=cut

1;
