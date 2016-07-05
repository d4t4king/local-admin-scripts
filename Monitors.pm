#!/usr/bin/perl

package Monitors;

use strict;
use warnings;

require 5.010;
use feature qw( switch );
no if $] ge '5.018', warnings => "experimental::smartmatch";

use Data::Dumper;
use Term::ANSIColor;

use Monitors::Adapter;
use Monitors::Sensor;

our %from_bool	= ( 'true'=>1, 'false'=>0 );
our %to_bool	= ( 1=>'true', 0=>'false' );

sub ltrim { my $s = shift(@_); $s =~ s/^\s+//;       return $s; }
sub rtrim { my $s = shift(@_); $s =~ s/\s+$//;       return $s; }
sub  trim { my $s = shift(@_); $s =~ s/^\s+|\s+$//g; return $s; }

sub sensor_parse {

	my $class 		= shift(@_);
	my $sensor_data	= shift(@_);
	my $verbose		= shift(@_) or 0;

	# A "section" will consist of a series of sensors and temperatures that are connected to a
	# given sensor "bus", and/or "adapter".
	my @lines = split(/\n/m, $sensor_data);
	#print Dumper(\@lines);

	my ($bus,$adapter,$node);
	my $adpt = Monitors::Adapter->new;
	foreach my $l ( @lines ) {
		#$l = &trim($l);
		# initialize the variables for each sensor object
		my ($sensor,$temp);
		given ($l) {
			when (/([a-z]+\-[a-z]+\-\d+)/) {
				$bus = $1;
				print "Bus: $bus \n" if ($verbose);
				if ((defined($bus)) and ($bus ne "")) {
					$adpt->{'bus'} = $bus;
				} else {
					warn colored("Matched circuit, but didn't get bus ID! \n", "yellow");
				}
			}
			when (/Adapter: (.*)/) {
				$adapter = $1;
				print "Adapter: $adapter \n" if ($verbose);
				if ((defined($adapter)) and ($adapter ne "")) {
					$adpt->{'adapter'} = $adapter;
				} else {
					warn colored("Matched adapter line, but didn't get adapter! \n", "yellow");
				}
			}
			# when we get this line, create a new sensor object and add it to the Adapter
			when (/(temp(\d+))\:/) {
				$node = $1; my $nodeid = $2;
				my $sens = Monitors::Sensor->new($node,"");
				$adpt->{'sensors'}{$node} = $sens;
			}
			when (/(Core\s+(\d+))\:/) {
				$node = $1; my $nodeid = $2;
				my $sens = Monitors::Sensor->new($node,"");
				$adpt->{'sensors'}{$node} = $sens;
			}
			when (/(Physical\s+id\s*(\d+))\:/) {
				$node = $1; my $nodeid = $2;
				my $sens = Monitors::Sensor->new($node,"");
				$adpt->{'sensors'}{$node} = $sens;
			}
			when (/(Ch\.\s+\d+\s+DIMM\s+\d+)\:/) {
				$node = $1; my $nodeid = $2;
				my $sens = Monitors::Sensor->new($node,"");
				$adpt->{'sensors'}{$node} = $sens;
			}
			when (/([Ee]xhaust)\s*\:/) {
				$node = $1;
				my $sens = Monitors::Sensor->new($node,"");
				$adpt->{'sensors'}{$node} = $sens;
			}
			when (/(T[a-zA-Z0-9]{3}):/) {
				$node = $1;
				my $sens = Monitors::Sensor->new($node,"");
				$adpt->{'sensors'}{$node} = $sens;
			}
			when (/(temp\d+\_(?:input|min|alarm|max(?:\_hyst)?|crit(?:\_(?:alarm|hyst))?|emergency(?:\_hyst)?)):\s+(\d+\.\d+)/) {
				$sensor = $1; $temp = $2;
				print "Sensor: $sensor \n" if ($verbose);
				print "Temp: $temp \n" if ($verbose);
				if (((defined($sensor)) and ($sensor ne "")) and 
					((defined($temp)) and ($temp ne ''))) {
					given ($sensor) {
						when (/(temp\d+)\_input/) {
							my $s = $1;
							if ($node =~ /(?:Core|Ch.\s+\d+DIMM\d+|Physical\s+id)\s+\d/) { $s = "$node"; }
							$adpt->{'sensors'}{$s}->{'input_temp'} = $temp;
							$adpt->{'sensors'}{$s}->{'fully_qualified_name'} = "$bus::$adapter::$node::$sensor";
						}
						when (/(temp\d+)\_alarm/) {
							my $s = $1;
							if ($node =~ /(?:Core|Ch.\s+\d+DIMM\d+|Physical\s+id)\s+\d/) { $s = "$node"; }
							$adpt->{'sensors'}{$s}->{'alarm_temp'} = $temp;
						}
						when (/(temp\d+)\_min/) {
							my $s = $1;
							if ($node =~ /(?:Core|Ch.\s+\d+DIMM\d+|Physical\s+id)\s+\d/) { $s = "$node"; }
							$adpt->{'sensors'}{$s}->{'min_temp'} = $temp;
						}
						when (/(temp\d+)\_max\_hyst/) {
							my $s = $1;
							if ($node =~ /(?:Core|Ch.\s+\d+DIMM\d+|Physical\s+id)\s+\d/) { $s = "$node"; }
							$adpt->{'sensors'}{$s}->{'max_hyst'} = $temp;
						}
						when (/(temp\d+)\_max$/) {
							my $s = $1;
							if ($node =~ /(?:Core|Ch.\s+\d+DIMM\d+|Physical\s+id)\s+\d/) { $s = "$node"; }
							$adpt->{'sensors'}{$s}->{'max_temp'} = $temp;
						}
						when (/(temp\d+)\_crit\_alarm/) {
							my $s = $1;
							if ($node =~ /(?:Core|Ch.\s+\d+DIMM\d+|Physical\s+id)\s+\d/) { $s = "$node"; }
							$adpt->{'sensors'}{$s}->{'crit_alarm'} = $temp;
						}
						when (/(temp\d+)\_crit\_hyst/) {
							my $s = $1;
							if ($node =~ /(?:Core|Ch.\s+\d+DIMM\d+|Physical\s+id)\s+\d/) { $s = "$node"; }
							$adpt->{'sensors'}{$s}->{'crit_hyst'} = $temp;
						}
						when (/(temp\d+)\_crit/) {
							my $s = $1;
							if ($node =~ /(?:Core|Ch.\s+\d+DIMM\d+|Physical\s+id)\s+\d/) { $s = "$node"; }
							$adpt->{'sensors'}{$s}->{'crit_temp'} = $temp;
						}
						when (/(temp\d+)\_emergency\_hyst/) {
							my $s = $1;
							if ($node =~ /(?:Core|Ch.\s+\d+DIMM\d+|Physical\s+id)\s+\d/) { $s = "$node"; }
							$adpt->{'sensors'}{$s}->{'emerg_hyst'} = $temp;
						}
						when (/(temp\d+)\_emergency/) {
							my $s = $1;
							if ($node =~ /(?:Core|Ch.\s+\d+DIMM\d+|Physical\s+id)\s+\d/) { $s = "$node"; }
							$adpt->{'sensors'}{$s}->{'emerg_temp'} = $temp;
						}
						default {
							print "S: $sensor\t\tT: $temp \n";
						}
					} # given()
				} else {
					warn colored("Matched sensor line, but didn't get sensor or temp! \n", "yellow");
				} # if/else
			}
			when (/\s*(fan\d+(?:\_(?:input|min|max))?)\:\s*([0-9.]+)?/) {
				#$sensor = $1; $temp = $2;
				#print "Sensor: $sensor \n" if ($verbose);
				#print "Temp: $temp \n" if ($verbose);
				#if (((defined($sensor)) and ($sensor ne "")) and 
				#	((defined($temp)) and ($temp ne ''))) {
				#	given ($sensor) {
				#		when (/(fan\d+)\_input/) {
				#			my $s = $1;
				#			if ($node =~ /([Ee]xhaust)/) { $s = "$node"; }
				#			$adpt->{'sensors'}{$s}{'fan_input'} = $temp;
				#		}
				#		when (/(fan\d+)\_min/) {
				#			my $s = $1;
				#			if ($node =~ /([Ee]xhaust)/) { $s = "$node"; }
				#			$adpt->{'sensors'}{$s}{'fan_min'} = $temp;
				#		}
				#		when (/(fan\d+)\_max/) {
				#			my $s = $1;
				#			if ($node =~ /([Ee]xhaust)/) { $s = "$node"; }
				#			$adpt->{'sensors'}{$s}{'fan_max'} = $temp;
				#		}
				#		default {
				#			print "S: $sensor\t\tT: $temp \n";
				#		}
				#	}
				#} else {
				#	warn colored("Matched sensor line,  but didn't get sensor or temp! \n", "yellow");
				#}
				# not a temperature sensors
				# we'll deal with fan sensors later
				next;
			}
			default {
				# if we get here, there is something wrong or unexpected.
				warn colored("Unrecognized section line: |$l| \n", "bold red");
			} # given()
		}
	}
	#my $sensor_obj = Monitors::Sensor->new($circid,$adapter,$node,$sensor,$temp);
	#$sensor_obj->{'crit_max'} = $sensor_obj->{'max_temp'} unless ($sensor_obj->{'crit_max'} != 0);
	#$sensor_obj->{'emerg_temp'} = $sensor_obj->{'crit_temp'} unless ((defined($sensor_obj->{'emerg_temp'})) and ($sensor_obj->{'emerg_temp'} != 0));
	#$sensor_obj->{'emerg_max'} = $sensor_obj->{'crit_max'} unless ((defined($sensor_obj->{'emerg_max'})) and ($sensor_obj->{'emerg_max'} != 0));
	#print Dumper($adpt);

	return $adpt;
}

sub get_binary {
	my $rtv		= 1;
	my $self	= shift(@_);
	my $bin		= shift(@_);

	my $bin_path = `which $bin`;
	chomp($bin_path);

	if ((!defined($bin_path)) or ($bin_path eq "")) {
		warn colored("Unable to find the `$bin` utility! \n", "yellow");
		return undef;
	} else {
		return $bin_path;
	}
}

1;
