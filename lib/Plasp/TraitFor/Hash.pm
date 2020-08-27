package Plasp::TraitFor::Hash;

use Moo::Role;

=head1 NAME

Plasp::TraitFor::Hash - Limited helper trait for HashRef attributes

=head1 SYNOPSIS

  use MyClass;

  with 'Plasp::TraitFor::Hash';

  has 'foo' => ();

  sub foo_get    { my $self = shift; __hash_get( $self->foo, @_ ); }
  sub foo_set    { my $self = shift; __hash_set( $self->foo, @_ ); }
  sub foo_exists { my $self = shift; __hash_exists( $self->foo, @_ ); }

=head1 DESCRIPTION

This trait provides I<some> native delegation methods for hash references.
Refer to L<https://metacpan.org/pod/Moose::Meta::Attribute::Native::Trait::Hash>

=head1 PROVIDED HETHODS

=over

=item __hash_get($hashref, $key, $key2, $key3...)

Returns values from the hash.

In list context it returns a list of values in the hash for the given keys. In scalar context it returns the value for the last key specified.

This method requires at least one argument.

=cut

sub __hash_get {
    my $hashref = shift;

    return map { $hashref->{$_} } @_ if wantarray;

    return $hashref->{pop( @_ )};
}

=item __hash_set($hashref, $key => $value, $key2 => $value2...)

Sets the elements in the hash to the given values. It returns the new values set for each key, in the same order as the keys passed to the method.

This method requires at least two arguments, and expects an even number of arguments.

=cut

sub __hash_set {
    my $hashref = shift;

    my ( @return, $key, $value );

    while ( @_ ) {
        ( $key, $value ) = ( shift, shift );
        $hashref->{$key} = $value;
        push @return, $value;
    }

    return wantarray ? ( @return ) : $value;
}

=item __hash_exists($hashref, $key)

Returns true if the given key is present in the hash.

This method requires a single argument.

=cut

sub __hash_exists {
    my ( $hashref, $key ) = @_;

    return exists $hashref->{$key};
}

1;

=back
