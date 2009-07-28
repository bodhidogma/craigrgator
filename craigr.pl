#! /usr/bin/perl

use strict;
use LWP;
use XML::RSS;

use constant {
	CRAIG_URL	=> "http://sfbay.craigslist.org/search/cta?maxAsk=%d&minAsk=%d&query=%s&srchType=T&format=rss",
};

# rss interesting elements:
#  - num_items
#  - version
#  - items
#    - title
#    - link
#    - description
#    - dc
#		- source
#		- date
#		- title

sub print_items()
{
	my ($rss) = @_;

	foreach my $item (@{$rss->{'items'}}) {
		print "t: $item->{'title'}\n";
		print "l: $item->{'link'}\n";
		print "\n";
	}
}

sub dump_items()
{
	my ($rss) = @_;

	foreach my $item (@{$rss->{'items'}}) {
		print "t: $item->{'title'}\n";
		print "l: $item->{'link'}\n";
		while (my ($k,$v) = each (%{$item->{'dc'}})) {
			print "kv: $k => $v\n";
		}
		print "--\n";
	}
}

sub main()
{
	my $RSS = new XML::RSS;
	my $UA = LWP::UserAgent->new();
	my $req = sprintf( CRAIG_URL, 25000, 18000, "bmw%203" );
	my $res;

	$res = $UA->get( $req );
	$RSS->parse( $res->decoded_content );

#	&print_items( $RSS );
	&dump_items( $RSS );

	#print "r: ". $res->decoded_content ."\n";
#	print "r: ".$RSS->as_string."\n";
}

&main( @ARGV );
