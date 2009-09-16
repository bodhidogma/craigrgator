#! /usr/bin/perl
#
use strict;

use lib 'lib';
use DB_File;

use Algorithm::NaiveBayes;


# Hash with two levels of keys: $words{category}{word} gives count of
# 'word' in 'category'.  Tied to a DB_File to keep it persistent.

my %words;
tie %words, 'DB_File', 'words.db';

# Read a file and return a hash of the word counts in that file

sub parse_file
{
    my ( $file ) = @_;
    my %word_counts;

    # Grab all the words with between 3 and 44 letters

    open FILE, "<$file";
    while ( my $line = <FILE> ) {
        while ( $line =~ s/([[:alpha:]]{3,44})[ \t\n\r]// ) {
            $word_counts{lc($1)}++;
        }
    }
    close FILE;
    return %word_counts;
}

# Add words from a hash to the word counts for a category
sub add_words
{
    my ( $category, %words_in_file ) = @_;

	if (1) {
	my $nb = Algorithm::NaiveBayes->new;
	if (-s 'nb.dat') {
		$nb = Algorithm::NaiveBayes->restore_state('nb.dat');
	}

	$nb->add_instance( attributes=> \%words_in_file, label => [$category] );

#	$nb->add_instance( attributes=> {chrome=>3,air =>2}, label => ['footest'] );

	$nb->save_state('nb.dat');

#	my $state = $nb->save_state_var();
#	print "st: $state\n";
#	while (my ($k,$v) = each (%{$state})) { print "kv: $k => $v\n"; }

	# Find results for unseen instances
#	$nb->train;
#	my $result = $nb->predict (attributes => {bar=>3,air=>2});
#	my $result = $nb->predict (attributes => \%words_in_file, noscale=>1);

#	print "resut: ".%{$result}."\n";
#	while (my ($k,$v) = each (%{$result})) { print "kv: $k => $v\n"; }
	}

	if (0) {
	my $nb = Algorithm::NaiveBayes->new;
	$nb->add_instance( attributes=> \%words_in_file, label => 'self' );
	$nb->train;
	my $result = $nb->predict (attributes => \%words_in_file,noscale=>1);
#	print "resut: ".%{$result}."\n";
	while (my ($k,$v) = each (%{$result})) { print "kv: $k => $v\n"; }
	}
}

# Get the classification of a file from word counts
sub classify
{
    my ( $nb, %words_in_file ) = @_;

	my $nb = Algorithm::NaiveBayes->new;
	if (-s 'nb.dat') {
		$nb = Algorithm::NaiveBayes->restore_state('nb.dat');
	}

	$nb->train;
	my $result = $nb->predict (attributes => \%words_in_file, noscale=>0);

#	print "resut: ".%{$result}."\n";
	while (my ($k,$v) = each (%{$result})) { print "kv: $k => $v\n"; }
}

# Supported commands are 'add' to add words to a category and
# 'classify' to get the classification of a file

if ( ( $ARGV[0] eq 'add' ) && ( $#ARGV == 2 ) ) {
    add_words( $ARGV[1], parse_file( $ARGV[2] ) );
} elsif ( ( $ARGV[0] eq 'c' ) && ( $#ARGV == 1 ) ) {
    classify( parse_file( $ARGV[1] ) );
} else {
    print <<EOUSAGE;
Usage: add <category> <file> - Adds words from <file> to category <category>
       c <file>       - Outputs classification of <file>
EOUSAGE
}

untie %words;
