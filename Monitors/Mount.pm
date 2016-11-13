#!/usr/bin/perl

package Monitors::Mount;
use base ('Monitors');

our @EXPORT		= qw( new );
our @EXPORT_OK	= qw( );
{
	$Monitors::Mount::VERSION = '0.0.1';
}
#our $VERSION	= '0.0.1';

use strict;
use warnings;

use Data::Dumper;
use Term::ANSIColor;

use lib "/root/local-admin-scripts";
use Monitors;

sub new {
	my $class = shift(@_);

	my $self = {
		'mount_point'		=>	shift(@_),
		'device_node'		=>	shift(@_),
		'blocks'			=>	0,
		'free'				=>	0,
		'used'				=>	0,
		'percent'			=>	0,
		'calc_percent_free'	=>	0,
		'temp_celsius'		=>	0,
		'bad_sectors'		=>	0,
		'bad_blocks'		=>	0,
		'failed_reads'		=>	0,
	};

	my $df		= Monitors->get_binary('df');
	my $grep	= Monitors->get_binary('grep');

	my $disk = `$df | $grep "$self->{'device_node'}"`;
	chomp($disk);
	#print STDERR colored("$disk \n", "magenta");

	if ($disk =~ /(\/dev\/x?(?:[sv]d[a-f]\d|disk\/by-label\/DOROOT|mapper\/opt_crypt|dm\-\d))\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\%\s+(.*)/) {
		my $fs = $1; $self->{'blocks'} = $2; $self->{'used'} = $3; 
		$self->{'free'} = $4; $self->{'percent'} = $5; my $mnt = $6;
	} elsif ($disk =~ /(\/\/(?:\d{1,3}\.){3}\d{1,3}\/.*?\/?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\%\s+(.*)/) {
		my $fs = $1; $self->{'blocks'} = $2; $self->{'used'} = $3; 
		$self->{'free'} = $4; $self->{'percent'} = $5; my $mnt = $6;
	} elsif ($disk =~ /(\/dev\/mapper\/.*-?(?:-vg)?-root)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\%\s*(\/.*)/) {
		my $fs = $1; $self->{'blocks'} = $2; $self->{'used'} = $3; 
		$self->{'free'} = $4; $self->{'percent'} = $5; my $mnt = $6;
	} else {
		die colored("Unable to match disk: $self->{'device_node'}!", "bold red");
	}
	
	$self->{'calc_percent_free'} = &__get_percent_free__($self->{'blocks'}, $self->{'free'});

	bless $self, $class;

	return $self;
}

sub __get_percent_free__ {
	my $t 		= shift(@_);
	my $f		= shift(@_);

	#print Dumper(\@_);

	die colored("Total bytes was empty!", "bold red") if ((!defined($t)) or ($t == 0));

	my $cp = ($f * 100) / $t;

	return sprintf("%-3.4f", $cp);
}

1;
