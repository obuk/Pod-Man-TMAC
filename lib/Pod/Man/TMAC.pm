package Pod::Man::TMAC;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use parent qw(Pod::Man);
use File::Spec;
use Slurp;

BEGIN {
  my $parent = \&Pod::Perldoc::DEBUG if defined &Pod::Simple::DEBUG;
  unless (defined &DEBUG) {
    *DEBUG = $parent || sub () { 10 };
  }
}

sub _elem {
  if (@_ > 2) { return $_[0]{$_[1]} = $_[2] }
  else        { return $_[0]{$_[1]}         }
}

for my $subname (qw/utf8 section name no_default_preamble search_path add_preamble/) {
  no strict 'refs';
  *$subname = do { use strict 'refs'; sub () { shift->_elem($subname, @_) } };
}

sub _list {
  map split(/[,;]/), map { ref ? @{$_} : $_ } grep defined, @_;
}


# add user's preambles to the default preamble. need to use
# add_preamble and search_path first.

sub preamble_template {
  my $self = shift;
  my $preamble;

  if ($self->no_default_preamble) {
    if (DEBUG) {
      $preamble .= ".\\\" no default preamble\n";
    }
  } else {
    $preamble .= $self->SUPER::preamble_template(@_);
  }
  for (qw/add_preamble search_path/) {
    if (DEBUG >= 4) {
      $preamble .= ".\\\"    $_: " . join(', ', _list($self->$_)) . "\n";
    }
  }
  my %seen;
  for my $tmac (grep !$seen{$_}++, _list($self->add_preamble)) {
    my ($found) = grep -f, $tmac, map File::Spec->catfile($_, $tmac),
      _list($self->search_path);
    if (DEBUG) {
      $preamble .= ".\\\" $tmac" . (
        $found ? $tmac eq $found ? ": found" : " => $found" : ": not found"
      ) . "\n";
    }
    $preamble .= slurp $found if $found;
  }
  $preamble;
}


# XXXXX - item_common seems to be unable to clean up the equivalent of
# blank lines after =item, for example lines only X <>, =begin comment
# to =end comment.

# I'll try to use it temporarily for a while here.

sub item_common {
    my ($self, $type, $attrs, $text) = @_;

    my $line = $$attrs{start_line};
    DEBUG > 3 and print "  $type item (line $line): $text\n";

    # Clean up the text.  We want to end up with two variables, one ($text)
    # which contains any body text after taking out the item portion, and
    # another ($item) which contains the actual item text.
    $text =~ s/\s+$//;
    my ($item, $index);
    if ($type eq 'bullet') {
        $item = "\\\(bu";
        #$text =~ s/\n*$/\n/;	# XXXXX
        $text =~ s/\n+$/\n/;	# XXXXX
    } elsif ($type eq 'number') {
        $item = $$attrs{number} . '.';
    } else {
        $item = $text;
        $item =~ s/\s*\n\s*/ /g;
        $text = '';
        $index = $item if ($item =~ /\w/);
    }

    # Take care of the indentation.  If shifts and indents are equal, close
    # the top shift, since we're about to create an indentation with .IP.
    # Also output .PD 0 to turn off spacing between items if this item is
    # directly following another one.  We only have to do that once for a
    # whole chain of items so do it for the second item in the change.  Note
    # that makespace is what undoes this.
    if (@{ $$self{SHIFTS} } == @{ $$self{INDENTS} }) {
        $self->output (".RE\n");
        pop @{ $$self{SHIFTS} };
    }
    $self->output (".PD 0\n") if ($$self{ITEMS} == 1);

    # Now, output the item tag itself.
    $item = $self->textmapfonts ($item);
    $self->output ($self->switchquotes ('.IP', $item, $$self{INDENT}));
    $$self{NEEDSPACE} = 0;
    $$self{ITEMS}++;
    $$self{SHIFTWAIT} = 0;

    # If body text for this item was included, go ahead and output that now.
    if ($text) {
        $text =~ s/\s*$/\n/;
        $self->makespace;
        $self->output ($self->protect ($self->textmapfonts ($text)));
        $$self{NEEDSPACE} = 1;
    }
    $self->outindex ($index ? ('Item', $index) : ());
}

1;
__END__

=encoding utf-8

=head1 NAME

Pod::Man::TMAC - add user's preambles.

=head1 SYNOPSIS

    use Pod::Man::TMAC;
    my $pod2man = Pod::Man::TMAC->new();
    $pod2man->add_preamble('user.tmac');
 
    # search directories if needed
    $pod2man->search_path(\@dir);
 
    # to override Pod::Man preamble
    $pod2man->no_default_preamble(1);
 
    # use utf8 for non-ASCII characters
    $pod2man->utf8(1);

=head1 LICENSE

Copyright (C) KUBO, Koichi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

KUBO, Koichi E<lt>k@obuk.orgE<gt>

=cut

