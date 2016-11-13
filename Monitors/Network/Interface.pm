#!/usr/bin/perl -w

package Monitors::Network::Interface;
use base "Monitors::Network";

#use Exporter;
#our @ISA		= qw( Exporter );
our @EXPORT		= qw( new to_bits to_Kb to_KB to_Mb to_MB to_Gb to GB );
our @EXPORT_OK	= qw( );
{
	$Monitors::Network::Interface::VERSION = '0.0.1';
}
#our $VERSION = '0.0.1';

use strict;
use warnings;

use feature qw( switch );
no if $] ge '5.018', warnings => "experimental::smartmatch";

use Data::Dumper;
use Term::ANSIColor;

sub new {
	my $class = shift;
	my $self = {
		'id'	=>	shift,
		'name'	=>	shift,
		'raw'	=>	shift,
	};

	bless $self, $class;

	$self->populate();


	return $self;
}

# assume all inputs to the below methods
# is bytes
sub to_bits {
	my $self = shift;
	my $bytes = shift;
	return ($bytes * 8);
} 
sub to_Kb {
	my $self = shift;
	my $bytes = shift;
	return (($bytes * 8) / 1024);
}
sub to_KB {
	my $self = shift;
	my $bytes = shift;
	return ($bytes / 1024);
}
sub to_Mb {
	my $self = shift;
	my $bytes = shift;
	return (($bytes * 8) / (1024 * 1024));
}
sub to_MB {
	my $self = shift;
	my $bytes = shift;
	return ($bytes / (1024 * 1024));
}
sub to_Gb {
	my $self = shift;
	my $bytes = shift;
	return (($bytes * 8) / (1024 * 1024 * 1024));
}
sub to_GB {
	my $self = shift;
	my $bytes = shift;
	return ($bytes / (1024 * 1024 * 1024));
}
sub get_errors_percent {
	my $self = shift;
	my $dir = shift;
	return -1 if ($self->{"${dir}_packets"} == 0);
	return (($self->{"${dir}_errors"} * 100) / $self->{"${dir}_packets"});
}
sub get_dropped_percent {
	my $self = shift;
	my $dir = shift;
	return -1 if ($self->{"${dir}_packets"} == 0);
	return (($self->{"${dir}_dropped"} * 100) / $self->{"${dir}_packets"});
}
sub populate {
	my $self	= shift(@_);
	#my $name	= shift(@_);
	#my $raw		= shift(@_);

	#print colored("$self->{'raw'}\n", "bold magenta");

	my $rx = 0; my $tx = 0;
	foreach my $l ( split(/\n/s, $self->{'raw'}) ) {
		given ($l) {
			when (/link\/(?:none|void).*/) {				next; }
			#5: vmnet8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN mode DEFAULT group default qlen 1000
			when (/\d+:\s+.*:\s+\<(?:(NO-CARRIER),)?(LOOPBACK|BROADCAST)\,(?:(MULTICAST)\,?)?(UP)?(?:\,(LOWER_UP))?\>\s+mtu\s+(\d+)\s+(.*)/) {
				my $c = $1; my $lb = $2; my $mcast = $3; my $up = $4; my $lup = $5; my $mtu = $6; my $flags = $7;
				#print "C: $c LB: $lb M: $mcast UP: $up LUP: $lup MTU: $mtu FLAGS: $flags \n";
				$self->{'MTU'} = $mtu;
			}
			#4: ipsec0: <NOARP> mtu 0 qdisc noop state DOWN mode DEFAULT qlen 10
			when (/\d+:\s+.*:\s+\<NOARP\>\s*mtu\s+(\d+)\s+(.*)/) {
				my $mtu = $1; my $flags = $2;
				$self->{'MTU'} = $mtu;
			}
		    #link/ether 00:50:56:c0:00:08 brd ff:ff:ff:ff:ff:ff promiscuity 0 
			when (/link\/(?:loopback|ether)\s+([0-9a-fA-F:]{17})\s+brd\s+([0-9a-fA-F:]{17})\s*(?:promiscuity\s(0|1))?/) {
				my $link = $1; my $mac = $2; my $arp_brd = $3; my $promisc = $4;
				$self->{'link'} = $link; $self->{'mac_addr'} = $mac; 
				$self->{'hw_broadcast'} = $arp_brd; $self->{'promiscuous_mode'} = $promisc;
			}
		    #RX: bytes  packets  errors  dropped overrun mcast   
		    when (/RX\:\s+bytes\s+packets\s+errors\s+dropped\s+overrun\s+mcast/) {		$rx = 1; $tx = 0; next; }
		    #TX: bytes  packets  errors  dropped carrier collsns 
		    when (/TX\:\s+bytes\s+packets\s+errors\s+dropped\s+carrier\s+collsns/) {	$rx = 0; $tx = 1; next; }
		    #0          0        0       0       0       0      
		    #0          40       0       0       0       0
			when (/(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/) {
				my $b = $1; my $p = $2; my $e = $3; my $d = $4; my $oc = $5; my $mc = $6; 
				if (($rx) and ($tx)) {
					die colored("Weird!  Xmit and Rcv should NOT be set at the same time!", "bold red");
				} elsif (($rx) and (!$tx)) {
					$self->{'rx_bytes'} = $b; $self->{'rx_packets'} = $p; $self->{'rx_errors'} = $e;
					$self->{'rx_dropped'} = $d; $self->{'rx_overrun'} = $oc; $self->{'rx_mcast'} = $mc;
				} elsif ((!$rx) and ($tx)) {
					$self->{'tx_bytes'} = $b; $self->{'tx_packets'} = $p; $self->{'tx_errors'} = $e;
					$self->{'tx_dropped'} = $d; $self->{'rx_carrier'} = $oc; $self->{'tx_collisions'} = $mc;
				} elsif ((!$rx) and (!$tx)) {
					warn colored("Looks like we got a data row before we were able to set Tx/Rx.", "yellow");
				} else { die colored("In Monitors::Network::Interface->populate: unexpected!", "bold red"); }
			}
			default { 
				print STDERR colored($l."\n", "bold red");
				die colored("We should never actually get here!", "bold red"); 
			}
		}
	}

	foreach my $dir ( qw( rx tx ) ) {
		$self->{"${dir}_errors_percent"} = $self->get_errors_percent($dir);
		$self->{"${dir}_dropped_percent"} = $self->get_dropped_percent($dir);
	}
}

1;
