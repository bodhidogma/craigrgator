#! /usr/bin/perl
#
use strict;
use DB_File;

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

    foreach my $word (keys %words_in_file) {
        $words{"$category-$word"} += $words_in_file{$word};
    }

	while (my ($k,$v) = each (%words)) {
		$v =~ s/^\s+//g;
		print "kv: $k => $v\n";
	}
}

# Get the classification of a file from word counts
sub classify
{
    my ( %words_in_file ) = @_;

    # Calculate the total number of words in each category and
    # the total number of words overall

    my %count;
    my $total = 0;
    foreach my $entry (keys %words) {
        $entry =~ /^(.+)-(.+)$/;
        $count{$1} += $words{$entry};
        $total += $words{$entry};
    }

    # Run through words and calculate the probability for each category

    my %score;
    foreach my $word (keys %words_in_file) {
        foreach my $category (keys %count) {
            if ( defined( $words{"$category-$word"} ) ) {
                $score{$category} += log( $words{"$category-$word"} /
                                          $count{$category} );
            } else {
                $score{$category} += log( 0.01 /
                                          $count{$category} );
            }
        }
    }
    # Add in the probability that the text is of a specific category

    foreach my $category (keys %count) {
        $score{$category} += log( $count{$category} / $total );
    }
    foreach my $category (sort { $score{$b} <=> $score{$a} } keys %count) {
        print "$category $score{$category}\n";
    }
}

# Supported commands are 'add' to add words to a category and
# 'classify' to get the classification of a file

if ( ( $ARGV[0] eq 'add' ) && ( $#ARGV == 2 ) ) {
    add_words( $ARGV[1], parse_file( $ARGV[2] ) );
} elsif ( ( $ARGV[0] eq 'classify' ) && ( $#ARGV == 1 ) ) {
    classify( parse_file( $ARGV[1] ) );
} else {
    print <<EOUSAGE;
Usage: add <category> <file> - Adds words from <file> to category <category>
       classify <file>       - Outputs classification of <file>
EOUSAGE
}

untie %words;
