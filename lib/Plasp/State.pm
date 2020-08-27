package Plasp::State;

use Module::Runtime qw(require_module);

use Moo::Role;
use Types::Standard qw(Object Str HashRef);

for my $type ( qw(Application Session) ) {
    has "${type}Class" => (
        is      => 'rw',
        isa     => Str,
        default => "Plasp::$type",
    );

    has "${type}Config" => (
        is      => 'rw',
        default => sub { {} },
    );

    has "$type" => (
        is      => 'ro',
        isa     => Object,
        clearer => "clear_$type",
        lazy    => 1,
        default => sub {
            my ( $self ) = @_;

            my $class_attr = "${type}Class";
            my $class = $self->$class_attr;

            require_module $class;

            # Create the state object
            my $config_attr = "${type}Config";
            return $class->new( asp => $self, %{$self->$config_attr} );
        }
    );
}


=item UseSessionIDParameter

Configuration flag to enable or disable using Session ID passed as query string
or form parameter. Enabled by default

=back

=cut

has 'UseSessionIDParameter' => (
    is      => 'rw',
    default => 1,
);

=item SessionIDKeyName

Use this to set the key name to use to reference the session-id passed via
request parameters or cookies

=back

=cut

has 'SessionIDKeyName' => (
    is      => 'rw',
    default => 'session-id',
);

sub _read_session_id {
    my ( $self ) = @_;

    return $self->_session_id_from_form
        || $self->_session_id_from_url
        || $self->_session_id_from_cookie;
}

sub _session_id_from_form {
    my ( $self ) = @_;

    my ( $id );

    if ( $self->UseSessionIDParameter ) {
        $id = $self->Request->Form( $self->SessionIDKeyName );
    }

    return $id;
}

sub _session_id_from_url {
    my ( $self ) = @_;

    my ( $id );

    if ( $self->UseSessionIDParameter ) {
        $id = $self->Request->QueryString( $self->SessionIDKeyName );
    }

    return $id;
}

sub _session_id_from_cookie {
    my ( $self ) = @_;

    return $self->Request->Cookies( $self->SessionIDKeyName );
}

sub _set_session_id {
    my ( $self, $id ) = @_;

    return unless $id;

    $self->Response->Cookies( $self->SessionIDKeyName, $id );
}

1;
