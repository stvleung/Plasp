package Plasp::TraitFor::Bool;

use Moo::Role;

=head1 NAME

Plasp::TraitFor::Bool - Limited helper trait for Bool attributes

=head1 SYNOPSIS

  use MyClass;

  with 'Plasp::TraitFor::Bool';

  has 'foo' => ();

  sub foo_set   { __bool_set( \( shift->{foo} ) ); }
  sub foo_unset { __bool_unset( \( shift->{foo} ) ); }

=head1 DESCRIPTION

This trait provides I<some> native delegation methods for boolean values. A
boolean is a scalar which can be 1, 0, "", or undef.

=head1 PROVIDED HETHODS

None of these methods accept arguments.

=over

=item __bool_set($boolref)

Sets the value to 1 and returns 1.

=cut

sub __bool_set {
    my $boolref = shift;

    return $$boolref = 1;
}

=item __bool_unset($boolref)

Set the value to 0 and returns 0.

=cut

sub __bool_unset {
    my $boolref = shift;

    return $$boolref = 0;
}

1;

=back
