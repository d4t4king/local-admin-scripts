#!/usr/bin/perl

package Monitors::Network;
use base 'Monitors';

#use Exporter;
#our @ISA		= qw( Exporter );
our @EXPORT		= qw( new parse_interfaces );
our @EXPORT_OK	= qw( );
{
	$Monitors::Network::VERSION = '0.0.1';
}
#our $VERSION = '0.0.1';

use Data::Dumper;
use Term::ANSIColor;

use lib '/root/local-admin-scripts';
use Monitors;
use Monitors::Network::Interface;

sub new {
	my $class = shift;
	my $self = {
		id			=>	shift,
		name		=>	shift,
		interfaces	=>	[]
	};

	bless $self, $class;

	my @ifaces = $self->parse_interfaces();

	return $self;
}

sub parse_interfaces{
	my $self = shift;

	my $ip_bin 	= Monitors->get_binary('ip');
	my $grep	= Monitors->get_binary('grep');
	my $cut		= Monitors->get_binary('cut');

	print "BIN: $ip_bin $grep $cut \n" if (($verbose) and ($verbose > 1));

	@ifaces = qx($ip_bin link | $grep '^[0-9]: ' | $cut -d: -f1,2);
	#print Dumper(\@ifaces);

	foreach ( @ifaces ) {
		chomp(); 
		my ($id, $name) = split(/:\s/);
		#print STDERR colored("$ip_bin -s -d link show $name \n", "bold yellow");
		my $out = qx($ip_bin -s -d link show $name);
		#print colored("$out \n", "bold blue");
		my $iobj = Monitors::Network::Interface->new($id,$name,$out);
		#print colored(Dumper($iobj)."\n", "bold cyan");
		push @{$self->{'interfaces'}}, $iobj;
	}
}

1;
