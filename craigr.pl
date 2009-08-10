#! /usr/bin/perl

# $Id$

use strict;
use LWP;
use XML::RSS;
use Getopt::Std;
use DBI();

use constant {
	DSN_DATA	=> "DBI:mysql:database=craigr;host=localhost",
	DSN_USER	=> "craigr",
	DSN_PWD		=> "craigr123",
	TMP_FILE	=> "/tmp/idesc.txt",
	CRAIG_URL	=> "http://sfbay.craigslist.org/search/cta?maxAsk=%d&minAsk=%d&query=%s&srchType=T&format=rss",
	MAX_PRICE	=> 25000,
	MIN_PRICE	=> 18000,
	MIN_YEAR	=> 2006,
	MAX_MILES   => 30000,
	QUERY		=> "bmw",
	LINKS_OPTS	=> "-no-references -no-numbering",
	RGX_TTLPRC	=> qr/([^\(]+).* \$(\d+)/,
	RGX_YEAR	=> qr/(200\d|^0\d) /,
	RGX_MODEL	=> qr/((Z3|Z4|M3|X3|X5|745|525|530|540|325|328|330)[ ]?[^c]i?)/i,
	RGX_LOCALE	=> qr/\(([^\)]+)\)/,
#	RGX_PRICE	=> qr/\$(\d+)/,
	RGX_MILES1	=> qr/ ([,\d]+[k?])( miles)?/i,
	RGX_MILES2	=> qr/mile.*: +([,\d]+)[ \n]/i,
	RGX_COLOR	=> qr/color:? +([:\w]+( [\w]+))/i,
	RGX_TRANS	=> qr/((automa|manu)[\w]*)/i,
	FEATURES	=> "bluetooth|folding|fold down|cold weather|navigation",
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
			$v =~ s/^\s+//g;
			print "$t kv: $k => $v\n";
			&dump_nodes( $v, ref($v), "$t\t" );
		}
		print "--\n";
	}
	elsif ($m eq "ARRAY" ) {
		foreach my $v (@$rss) {
			$v =~ s/^\s+//g;
			print "$t v: $v\n";
			&dump_nodes( $v, ref($v), "$t\t" );
		}
		print "--\n";
	}
#	else { }
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

# read from STDIN, a file or URL
sub readfile()
{
	my ($file, $req) = @_;
	my ($res, $fin);
	my $UA = LWP::UserAgent->new();

#	print "f: ($file) $req\n";
	if (defined($file)) {
		if ($file eq "-") { $fin = *STDIN{IO}; }
		else { open IN, "<$file"; $fin = *IN{IO}; }
		while (<$fin>){ $res .= $_; }
		close $fin; 
	}
	else {
		$res = $UA->get( $req )->decoded_content;
	}
#	print "r: $res";
	return $res;
}

sub parse_items()
{
	my ($rss, $verbose, $vmatch) = @_;
	my $dbh = DBI->connect( DSN_DATA, DSN_USER, DSN_PWD,
		{'RaiseError' => 0, 'PrintError' => 0} );

	my $sth = $dbh->prepare( "INSERT INTO autos (watch,title,link,cdate,rawinfo"
		.",location,year,make,model,color,miles,price,trans,features,keywords) "
		." VALUES(?,?,?,?,?"
		.",?,?,?,?,?,?,?,?,?,?)"
	) or die $dbh->errstr;

	foreach my $item (@{$rss->{'items'}}) {
		my (@info, $tdesc);
		my ($mstr,%data);
		@info = ($item->{'title'},
			$item->{'link'},
			$item->{'dc'}->{'date'},
			$item->{'description'}
		);
		$info[0] =~ s/^\s+//g; $info[0] =~ s/\s+/ /g;
		$info[3] =~ s/^\s+//g; $info[3] =~ s/\s+/ /g;

		# search for keyword data in TITLE
		if ($info[0] =~ RGX_TTLPRC) { $data{title} = $1; $data{price} = $2; }
		if ($info[0] =~ RGX_YEAR ) { $data{year} = $1; }
		if ($info[0] =~ RGX_LOCALE ) { $data{loc} = $1; }
#		if ($info[0] =~ RGX_PRICE ) {$data{price} = $1; }
		if ($info[0] =~ RGX_MODEL ) { $data{model} = $1; }
		if ($info[0] =~ RGX_MILES1 ) { $data{miles1} = $1; }

		open TMP, ">".TMP_FILE; print TMP $info[3]; close TMP;
		$tdesc = &dump_html( TMP_FILE, LINKS_OPTS );

#		print "T($match): $info[0]\n";
#		print "  d: $data{year}, $data{price}, $data{model}, $data{loc}, $data{miles1}";
#		print "\n";

		# search for keyword data in BODY 
		if ($tdesc =~ RGX_MILES2 ) { $data{miles2} = $1; }
		if ($tdesc =~ RGX_COLOR ) { $data{color} = $1; }
		if ($tdesc =~ RGX_TRANS ) { $data{trans} = $1; }
		if (!$data{model} && $tdesc =~ RGX_MODEL) { $data{model} = $1; }
		if (!$data{miles1} && $tdesc =~ RGX_MILES1) { $data{miles} = $1; }
		if (!$data{year} && $tdesc =~ RGX_YEAR) { $data{year} = $1; }
#		($data{color}) = split($data{color},

		my @feats = split( /\|/, FEATURES );
		foreach my $ftr (@feats) {
#			print "f: $ftr\n";
			if ($tdesc =~ m/($ftr)/i) { $data{feature} .= "$1, "; }
		}

		# clean up results;
		$data{model} =~ s/ //g;
		$data{miles1} =~ s/,//g;
		$data{miles2} =~ s/,//g;
		if ($data{year} < 20) { $data{year} += 2000; }
		if ($data{miles1} =~ m/(\d+)/) { $data{miles1} = $1*1000; }
		if ($data{miles1} > $data{miles2}) {$data{miles} = $data{miles1}; }
		else { $data{miles} = $data{miles2}; }
		if (! $data{miles}) { $data{miles} = 0; }
		if ($data{title} eq "") {$data{title} = $info[0]; }
		$data{title} =~ s/[ ]+$//;

		my $keywords;
		while (my ($k,$v) = each (%data)) {
			if ($v ne '') {
				$keywords .= "$k => $v\n";
			}
		}
		# is record an interesting match?
		$data{match} =
			(($data{year} >= MIN_YEAR
				&& $data{model}
				&& $data{miles} <= MAX_MILES) ? 1 : 0);

#		print "T($match): $info[0]\n";
#		print "  d: $data{color}, $data{miles}, $data{miles2}";
#		print "\n";
#		if ($data{model}) { print ">>$tdesc\n"; };
#		if ( $data{model} ) { print "T(): $info[0]\n"; print $keywords;
#			&dump_nodes( \%data, "HASH" );
#		}

		# log details in DB
#		print "s: $sql\n";
		if (1) {
			if (! $sth->execute( 
			 $data{match}, $data{title}, $info[1], $info[2],$info[3]
			, $data{loc}, $data{year}, "BMW", $data{model}, $data{color}, $data{miles}
			, $data{price}, $data{trans}, $data{feature}, $keywords
			)) {
#				print "err: $data{title}\t ".$dbh->errstr."\n";
				if ($dbh->errstr !~ m/Duplicate/) {
					print "err: ".$dbh->errstr."\n";
				}
			}
			else {
				print "+: $data{title}\n";
			}
		}

		# dump details
		if ($verbose =~ m/[tdlx]/){ print "T: $info[0]\n"; }
		if ($verbose =~ m/d/) { print "D: $info[2]\n"; }
		if ($verbose =~ m/l/) { print "L: $info[1]\n"; }
		if ($verbose =~ m/x/) { print "X: $tdesc\n"; }
	}

	&verify_links( 0, $dbh );
}

sub verify_links()
{
	my ($UA, $dbh) = @_;

	if ($dbh==0) {
		$dbh = DBI->connect( DSN_DATA, DSN_USER, DSN_PWD,
			{'RaiseError' => 0, 'PrintError' => 0} );
	}
	if ($UA==0) {
		$UA = LWP::UserAgent->new();
	}
	my $res;

	my $sthq = $dbh->prepare( "SELECT id,link,title FROM autos WHERE rem=0") or die $dbh->errstr;
	my $sthu = $dbh->prepare( "UPDATE autos SET rem=?,sdate=NOW() WHERE id=?" ) or die $dbh->errstr;

	if (! $sthq->execute) { die "Error: ".$dbh->errstr."\n"; }
	while (my $row = $sthq->fetchrow_arrayref) {
		my $rem = 0;
#		my $title;
#		if ($$row[2] =~ RGX_TTLPRC) { $title= $1; }
#		if ($title eq "") {$title = $$row[2]; }
#		$title =~ s/[ ]+$//;
#		print "id: $$row[0] - ($title) $$row[2]\n";

		$res = $UA->get( $$row[1] )->decoded_content;
		if ($res =~ m/posting has been deleted/) { $rem=1; }
		if ($res =~ m/posting has expired/) { $rem=2; }
		if ($res =~ m/flagged<\/a> for removal/) { $rem=3; }

		if ($rem) {
			print "-: $$row[0] -$rem- ($$row[2]) - $$row[1]\n";
			if (! $sthu->execute( $rem, $$row[0] ) ) { die $dbh->errstr; }
		}
#		else { print "id: $$row[0] -$rem- ($$row[2]) - $$row[1]\n"; }
	}
	
}

sub main()
{
	my (@args) = @_;
	my (%opts);
	my $RSS = new XML::RSS;
	my $req = sprintf( CRAIG_URL, MAX_PRICE, MIN_PRICE, &urlencode(QUERY) );
	my $res;

	getopts("ci:dv:m",\%opts);

	$res = &readfile( $opts{i}, $req );
	$RSS->parse( $res );

	if ($opts{d}) {
		&dump_nodes( $RSS, "HASH" );
	}
	elsif ($opts{c}) {
		&verify_links();
	}
	else {
		&parse_items( $RSS, $opts{v}, $opts{m} );
	}

	#print "r: ". $res->decoded_content ."\n";
#	print "r: ".$RSS->as_string."\n";
}

&main( @ARGV );
