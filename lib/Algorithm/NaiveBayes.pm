package Algorithm::NaiveBayes;

use strict;
use Storable;

use vars qw($VERSION);
$VERSION = '0.04';

sub new {
  my $package = shift;
  my $self = bless {
	      version => $VERSION,
	      purge => 1,
	      model_type => 'Frequency',
	      @_,
	      instances => 0,
	      training_data => {},
	     }, $package;
  
  if ($package eq __PACKAGE__) {
    # Bless into the proper subclass
    return $self->_load_model_class->new(@_);
  }
  
  return bless $self, $package;
}

sub _load_model_class {
  my $self = shift;
  die "model_class cannot be set to " . __PACKAGE__ if ($self->{model_class}||'') eq __PACKAGE__;
  my $package = $self->{model_class} || __PACKAGE__ . "::Model::" . $self->{model_type};
  unless ($package->can('new')) {
    eval "use $package";
    die $@ if $@;
  }
  return $package;
}

sub save_state {
  my ($self, $path) = @_;
  Storable::nstore($self, $path);
#  Storable::nstore($self->{model}, $path);
}

sub restore_state {
  my ($pkg, $path) = @_;
  my $self = Storable::retrieve($path)
    or die "Can't restore state from $path: $!";
  $self->_load_model_class;
  return $self;
}

sub save_state_var {
  my ($self) = @_;
  return Storable::freeze($self);
}

sub restore_state_var {
  my ($pkg, $var) = @_;
  my $self = Storable::thaw($var)
    or die "Can't restore state from var: $!";
  $self->_load_model_class;
  return $self;
}

sub add_instance {
  my ($self, %params) = @_;
  for ('attributes', 'label') {
#  print "> ".$params{$_}."\n";
    die "Missing required '$_' parameter" unless exists $params{$_};
  }
  for ($params{label}) {
    $_ = [$_] unless ref;
    @{$self->{labels}}{@$_} = ();
  }
#  print "> ".$params{attributes}{air}."\n"; print "> ".$params{label}->[0]."\n";
  $self->{instances}++;
  $self->do_add_instance($params{attributes}, $params{label}, $self->{training_data});
}

sub labels { keys %{ $_[0]->{labels} } }
sub instances  { $_[0]->{instances} }
sub training_data { $_[0]->{training_data} }

sub train {
  my $self = shift;
  $self->{model} = $self->do_train($self->{training_data});
  $self->do_purge if $self->purge;
}

sub do_purge {
  my $self = shift;
  delete $self->{training_data};
}

sub purge {
  my $self = shift;
  $self->{purge} = shift if @_;
  return $self->{purge};
}

sub predict {
  my ($self,%params) = @_;
  my $newattrs = $params{attributes} or die "Missing 'attributes' parameter for predict()";
  my $nscale = $params{noscale};
  return $self->do_predict($self->{model}, $newattrs, $nscale);
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Algorithm::NaiveBayes - Bayesian prediction of categories

=head1 SYNOPSIS

  use Algorithm::NaiveBayes;
  my $nb = Algorithm::NaiveBayes->new;

  $nb->add_instance
    (attributes => {foo => 1, bar => 1, baz => 3},
     label => 'sports');
  
  $nb->add_instance
    (attributes => {foo => 2, blurp => 1},
     label => ['sports', 'finance']);

  ... repeat for several more instances, then:
  $nb->train;
  
  # Find results for unseen instances
  my $result = $nb->predict
    (attributes => {bar => 3, blurp => 2});


=head1 DESCRIPTION

This module implements the classic "Naive Bayes" machine learning
algorithm.  It is a well-studied probabilistic algorithm often used in
automatic text categorization.  Compared to other algorithms (kNN,
SVM, Decision Trees), it's pretty fast and reasonably competitive in
the quality of its results.

A paper by Fabrizio Sebastiani provides a really good introduction to
text categorization:
L<http://faure.iei.pi.cnr.it/~fabrizio/Publications/ACMCS02.pdf>

=head1 METHODS

=over 4

=item new()

Creates a new C<Algorithm::NaiveBayes> object and returns it.  The
following parameters are accepted:

=over 4

=item purge

If set to a true value, the C<do_purge()> method will be invoked during
C<train()>.  The default is true.  Set this to a false value if you'd
like to be able to add additional instances after training and then
call C<train()> again.

=back

=item add_instance( attributes =E<gt> HASH, label =E<gt> STRING|ARRAY )

Adds a training instance to the categorizer.  The C<attributes>
parameter contains a hash reference whose keys are string attributes
and whose values are the weights of those attributes.  For instance,
if you're categorizing text documents, the attributes might be the
words of the document, and the weights might be the number of times
each word occurs in the document.

The C<label> parameter can contain a single string or an array of
strings, with each string representing a label for this instance.  The
labels can be any arbitrary strings.  To indicate that a document has no
applicable labels, pass an empty array reference.

=item train()

Calculates the probabilities that will be necessary for categorization
using the C<predict()> method.

=item predict( attributes =E<gt> HASH )

Use this method to predict the label of an unknown instance.  The
attributes should be of the same format as you passed to
C<add_instance()>.  C<predict()> returns a hash reference whose keys
are the names of labels, and whose values are the score for each
label.  Scores are between 0 and 1, where 0 means the label doesn't
seem to apply to this instance, and 1 means it does.

In practice, scores using Naive Bayes tend to be very close to 0 or 1
because of the way normalization is performed.  I might try to
alleviate this in future versions of the code.

=item labels()

Returns a list of all the labels the object knows about (in no
particular order), or the number of labels if called in a scalar
context.

=item do_purge()

Purges training instances and their associated information from the
NaiveBayes object.  This can save memory after training.

=item purge()

Returns true or false depending on the value of the object's C<purge>
property.  An optional boolean argument sets the property.

=item save_state($path)

This object method saves the object to disk for later use.  The
C<$path> argument indicates the place on disk where the object should
be saved:

  $nb->save_state($path);

=item restore_state($path)

This class method reads the file specified by C<$path> and returns the
object that was previously stored there using C<save_state()>:

  $nb = Algorithm::NaiveBayes->restore_state($path);

=back

=head1 THEORY

Bayes' Theorem is a way of inverting a conditional probability. It
states:

                P(y|x) P(x)
      P(x|y) = -------------
                   P(y)

The notation C<P(x|y)> means "the probability of C<x> given C<y>."  See also
L<"http://mathforum.org/dr.math/problems/battisfore.03.22.99.html">
for a simple but complete example of Bayes' Theorem.

In this case, we want to know the probability of a given category given a
certain string of words in a document, so we have:

                    P(words | cat) P(cat)
  P(cat | words) = --------------------
                           P(words)

We have applied Bayes' Theorem because C<P(cat | words)> is a difficult
quantity to compute directly, but C<P(words | cat)> and C<P(cat)> are accessible
(see below).

The greater the expression above, the greater the probability that the given
document belongs to the given category.  So we want to find the maximum
value.  We write this as

                                 P(words | cat) P(cat)
  Best category =   ArgMax      -----------------------
                   cat in cats          P(words)


Since C<P(words)> doesn't change over the range of categories, we can get rid
of it.  That's good, because we didn't want to have to compute these values
anyway.  So our new formula is:

  Best category =   ArgMax      P(words | cat) P(cat)
                   cat in cats

Finally, we note that if C<w1, w2, ... wn> are the words in the document,
then this expression is equivalent to:

  Best category =   ArgMax      P(w1|cat)*P(w2|cat)*...*P(wn|cat)*P(cat)
                   cat in cats

That's the formula I use in my document categorization code.  The last
step is the only non-rigorous one in the derivation, and this is the
"naive" part of the Naive Bayes technique.  It assumes that the
probability of each word appearing in a document is unaffected by the
presence or absence of each other word in the document.  We assume
this even though we know this isn't true: for example, the word
"iodized" is far more likely to appear in a document that contains the
word "salt" than it is to appear in a document that contains the word
"subroutine".  Luckily, as it turns out, making this assumption even
when it isn't true may have little effect on our results, as the
following paper by Pedro Domingos argues:
L<"http://www.cs.washington.edu/homes/pedrod/mlj97.ps.gz">


=head1 HISTORY

My first implementation of a Naive Bayes algorithm was in the
now-obsolete AI::Categorize module, first released in May 2001.  I
replaced it with the Naive Bayes implementation in AI::Categorizer
(note the extra 'r'), first released in July 2002.  I then extracted
that implementation into its own module that could be used outside the
framework, and that's what you see here.

=head1 AUTHOR

Ken Williams, ken@mathforum.org

=head1 COPYRIGHT

Copyright 2003-2004 Ken Williams.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 SEE ALSO

AI::Categorizer(3), L<perl>.

=cut
