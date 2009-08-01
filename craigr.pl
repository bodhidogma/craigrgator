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
#		- date

sub urlencode()
{
	my ($str) = @_;
	$str =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
	return $str;
}

# dump entire XML tree
sub dump_nodes()
{
	my ($rss, $m, $t) = @_;

	if ($m eq "HASH") {
		while (my ($k,$v) = each (%{$rss})) {
			print "$t kv: $k => $v\n";
#			if ((ref($v) eq "HASH") || (ref($v) eq "ARRAY")) {
				&dump_nodes( $v, ref($v), "$t\t" );
#			}
		}
		print "--\n";
	}
	elsif ($m eq "ARRAY" ) {
		foreach my $v (@$rss) {
			print "$t v: $v\n";
			&dump_nodes( $v, ref($v), "$t\t" );
		}
		print "--\n";
	}
	else {
#		print "r: $rss\n";
	}
#	print "--\n";
}

sub dump_html()
{
	my ($url, $opts) = @_;
	my ($out);

	open LINKS, "links -dump $opts $url|";
	while (<LINKS>) { $out .= $_; }
	close LINKS;

	return $out;
}

sub dump_items()
{
	my ($rss) = @_;

	my ($date, $desc, $rdesc);


	foreach my $item (@{$rss->{'items'}}) {
		print "t: $item->{'title'}\n";
		print "l: $item->{'link'}\n";
		$date = $item->{'dc'}->{'date'};
		print "d: $date\n";
		$desc = $item->{'description'};

		open TMP, ">/tmp/idesc.txt";
		print TMP $desc;
		close TMP;

		$rdesc = &dump_html( "/tmp/idesc.txt", "-no-references -no-numbering" );

		print "desc: $rdesc\n";

		print "--\n";
	}
}

sub main()
{
	my $RSS = new XML::RSS;
	my $UA = LWP::UserAgent->new();
	my $req = sprintf( CRAIG_URL, 25000, 18000, &urlencode("bmw 325") );
	my $res;

#	print "req: $req\n";

	$res = $UA->get( $req );
	$RSS->parse( $res->decoded_content );

#	&dump_nodes( $RSS, "HASH" );
	&dump_items( $RSS );

	#print "r: ". $res->decoded_content ."\n";
#	print "r: ".$RSS->as_string."\n";
}

&main( @ARGV );
