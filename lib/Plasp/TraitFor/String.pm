package Plasp::TraitFor::String;

use Moo::Role;

=head1 NAME

Plasp::TraitFor::String - Limited helper trait for String attributes

=head1 SYNOPSIS

  use MyClass;

  with 'Plasp::TraitFor::String';

  has 'foo' => ();

  sub foo_append { my $self = shift; __str_append( \( $self->{foo} ), @_ ); }
  sub foo_length { __str_length( \( shift->{foo} ) ); }
  sub foo_substr { __str_substr( \( shift->{foo} ) ); }

=head1 DESCRIPTION

This trait provides I<some> native delegation methods for strings.

=head1 PROVIDED HETHODS

None of these methods accept arguments.

=over

=item __str_append($stringref, $string)

Appends to the string, like .=, and returns the new value.

This method requires a single argument.

=cut

sub __str_append {
    my ( $stringref, $append ) = @_;

    return $$stringref .= $append;
}

=item __str_length($stringref)

Just like "length" in perlfunc, returns the length of the string.

=cut

sub __str_length {
    my $stringref = shift;

    return length( $$stringref );
}

=item __str_substr($stringref, $offset, $length, $replacement)

This acts just like "substr" in perlfunc. When called as a writer, it returns
the substring that was replaced, just like the Perl builtin.

This method requires at least one argument, and accepts no more than three.

=cut

sub __str_substr {
    my $stringref = shift;

    # There must be a less roundabout way to do this!
    # substr($$stringref, @_) does not do what you think because substr is a
    # function!
    my $args = join ',', @_;
    return eval "substr(\$\$stringref,$args)";
}

1;

=back
