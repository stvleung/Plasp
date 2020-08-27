package Plasp::State::Session;

use Moo::Role;

with 'Plasp::TraitFor::Bool';

requires qw(_fetch_session _store_session _delete_session);

has 'asp' => (
    is       => 'ro',
    isa      => sub { die "$_[0] is not a Plasp object!" unless ref $_[0] eq 'Plasp' },
    required => 1,
    weak_ref => 1,
);


=head1 NAME

Plasp::State::Session - Role for $Session objects

=head1 SYNOPSIS

  package MyApp::Session;

  with 'Plasp::State::Session';

  sub _fetch_session { ... }
  sub _store_session { ... }
  sub _delete_session { ... }

=head1 DESCRIPTION

The C<$Session> object keeps track of user and web client state, in a persistent
manner, making it relatively easy to develop web applications. The C<$Session>
state is stored across HTTP connections, in database files in the C<Global> or
C<StateDir> directories, and will persist across web server restarts.

The user session is referenced by a 128 bit / 32 byte MD5 hex hashed cookie, and
can be considered secure from session id guessing, or session hijacking. When a
hacker fails to guess a session, the system times out for a second, and with
2**128 (3.4e38) keys to guess, a hacker will not be guessing an id any time
soon.

If an incoming cookie matches a timed out or non-existent session, a new session
is created with the incoming id. If the id matches a currently active session,
the session is tied to it and returned. This is also similar to the Microsoft
ASP implementation.

The C<$Session> reference is a hash ref, and can be used as such to store data
as in:

    $Session->{count}++;     # increment count by one
    %{$Session} = ();   # clear $Session data

The C<$Session> object state is implemented through L<MLDBM>, and a user should
be aware of the limitations of MLDBM. Basically, you can read complex
structures, but not write them, directly:

  $data = $Session->{complex}{data};     # Read ok.
  $Session->{complex}{data} = $data;     # Write NOT ok.
  $Session->{complex} = {data => $data}; # Write ok, all at once.

Please see L<MLDBM> for more information on this topic. C<$Session> can also be
used for the following methods and properties:

=head1 ATTRIBUTES

=cut

has '_is_new' => (
    is      => 'rw',
    default => 0,
);

sub _set_is_new {
    my $self = shift;
    __bool_set( \( $self->{_is_new} ), @_ );
}

sub _unset_is_new {
    my $self = shift;
    __bool_unset( \( $self->{_is_new} ), @_ );
}

=over

=item $Session->{CodePage}

Not implemented.  May never be until someone needs it.

=cut

has 'CodePage' => (
    is => 'ro',
);

=item $Session->{LCID}

Not implemented.  May never be until someone needs it.

=cut

has 'LCID' => (
    is => 'ro',
);

=item $Session->{SessionID}

SessionID property, returns the id for the current session, which is exchanged
between the client and the server as a cookie.

=cut

has 'SessionID' => (
    is      => 'rw',
    isa     => sub { die "$_[0] is not a Str!" if ref $_[0] },
);

=item $Session->{Timeout} [= $minutes]

Timeout property, if minutes is being assigned, sets this default timeout for
the user session, else returns the current session timeout.

If a user session is inactive for the full timeout, the session is destroyed by
the system. No one can access the session after it times out, and the system
garbage collects it eventually.

=cut

has 'Timeout' => (
    is      => 'rw',
    isa     => sub { die "$_[0] is not a Str!" if ref $_[0] || $_[0] != int( $_[0] ) },
    default => 60,
);

=back

=head1 METHODS

=over

=item $Session->Abandon()

The abandon method times out the session immediately. All Session data is
cleared in the process, just as when any session times out.

=cut

has 'IsAbandoned' => (
    is      => 'rw',
    default => 0,
);

sub Abandon {
    my $self = shift;
    __bool_set( \( $self->{IsAbandoned} ), @_ );
}

=item $Session->Lock()

Not implemented. This is a no-op. This was meant to be for performance
improvement, but it's not necessary.

=cut

# TODO: will not implement
sub Lock {
    my ( $self ) = @_;
    $self->asp->log->warn( "\$Session->Lock has not been implemented!" );
    return;
}

=item $Session->UnLock()

Not implemented. This is a no-op. This was meant to be for performance
improvement, but it's not necessary.

=cut

# TODO: will not implement
sub UnLock {
    my ( $self ) = @_;
    $self->asp->log->warn( "\$Session->UnLock has not been implemented!" );
    return;
}

=item $Session->Flush()

Not implemented.

=cut

# TODO: will not implement; not part of API so just no-op
sub Flush { }

1;

=back

=head1 SEE ALSO

=over

=item * L<Plasp::Request>

=item * L<Plasp::Response>

=item * L<Plasp::Application>

=item * L<Plasp::Server>

=back
