package Plasp::App;

use Encode;
use File::Temp qw(tempdir);
use HTTP::Date qw(time2str);
use Path::Tiny;
use Plasp;
use Scalar::Util qw(blessed);
use Try::Tiny;

use Role::Tiny;
use namespace::clean;

=head1 NAME

Plasp::App - Create Plasp Plack App!

=head1 SYNOPSIS

In C<MyApp.pm>

  package MyApp;

  use Role::Tiny::With;

  with 'Plasp::App';

  1;

In C<app.psgi>

  use MyApp;

  $app = MyApp->new;

=head1 DESCRIPTION

Use L<Plasp::App> as a L<Role::Tiny> to create a new PSGI app. Call the C<new>
class method and get a subroutine in return which will serve a PSGI application.

=head1 CLASS METHODS

=over

=item $class->new(%config)

You can pass in the configuration in C<new>

  $app = MyApp->new(
    ApplicationRoot => '/var/www',
    DocumentRoot    => 'root',
    Global          => 'lib',
    GlobalPackage   => 'MyApp',
    IncludesDir     => 'templates',
    MailHost        => 'localhost',
    MailFrom        => 'myapp@localhost',
    XMLSubsMatch    => '(?:myapp):\w+',
    Error404Path    => '/error404.asp',
    Error500Path    => '/error500.asp',
    Debug           => 0,
  );

=cut

sub new {
    my ( $class, @args ) = @_;

    $class->config( @args );

    return $class->psgi_app;
}

=item $class->config(%config)

You can even set or override the configuration in another context either before
or after initialization;

  $app = MyApp->new;

  MyApp->config(ApplicationRoot => '/var/www');
  MyApp->config(DocumentRoot    => 'html');
  MyApp->config(Global          => 'lib');
  MyApp->config(GlobalPackage   => 'MyApp');
  MyApp->config(IncludesDir     => 'templates');

=cut

# Create config global variable in order to configure app as class method
my %_config;
sub config {
    my ( $class, @args ) = @_;

    if ( @args ) {
        my %hash = ref $args[0] eq 'HASH' ? %{$args[0]} : @args;
        my $attr;
        for $attr ( keys %hash ) {
            $_config{$attr} = $hash{$attr};
        }
        return defined $attr ? $_config{$attr} : undef;
    } else {
        return \%_config;
    }
}

=item $class->psgi_app

Alternatively, you can just call the C<psgi_app> class method, which is the
same as calling C<<$class->new>> without passing in any configuration.

  MyApp->config(
    ApplicationRoot => '/var/www',
    DocumentRoot    => 'root',
    Global          => 'lib',
    GlobalPackage   => 'MyApp',
    IncludesDir     => 'templates',
  );

  $app = MyApp->psgi_app;

=cut

# Create a global variable to cache ASP object
my $_asp;
sub psgi_app {
    my $class = shift;

    return sub {
        my $env = shift;

        # Create localized ENV because ASP modifies and assumes ENV being
        # populated with Request headers as in CGI
        local %ENV = %ENV;

        my ( $status, @headers, $body );

        try {
            # Create new Plack::Request object
            my $req = Plack::Request->new( $env );

            # Reuse cached Plasp object, else create new
            if ( $_asp ) {
                $_asp->req( $req );
            } else {
                $_asp = Plasp->new( %{$class->config}, req => $req );
            }

            # Render the ASP page
            # Parse and compile the ASP code
            my $compiled = $_asp->compile_file( path( $_asp->DocumentRoot, $req->path_info ) );

            # Execute code
            $_asp->GlobalASA->Script_OnStart;
            $_asp->execute( $compiled->{code} );
            $_asp->GlobalASA->Script_OnFlush;
        } catch {
            if ( $_asp && blessed( $_ ) ) {

                # If the file is not found, return HTTP 404
                if ( $_->isa( 'Plasp::Exception::NotFound' ) ) {

                    # Construct not found response
                    my $resp = $_asp->Response;
                    $resp->Status( 404 );
                    if ( $_asp->Error404Path ) {
                        $resp->Include( path( $_asp->DocumentRoot, $_asp->Error404Path )->stringify );
                    } else {
                        $resp->Body( '<!DOCTYPE html><html><head><title>Page Not Found</title></head><body><h1>Page Not Found</h1><p>Sorry, the page you are looking does not exist.</p></body></html>' );
                        $resp->ContentType( 'text/html' );
                    }

                # If error in other ASP code, return HTTP 500
                } elsif ( $_->isa( 'Plasp::Exception::Code' )
                    || ( !$_->isa( 'Plasp::Exception::End' )
                        && !$_->isa( 'Plasp::Exception::Redirect' ) ) ) {
                    $_asp->error( "Encountered application error: $_" );
                }

                # Plasp application reported errors
                if ( $_asp->has_errors ) {
                    # Construct error response
                    my $resp = $_asp->Response;
                    $resp->Status( $resp->Status || 500 );
                    if ( $_asp->Error500Path ) {
                        $resp->Include( path( $_asp->DocumentRoot, $_asp->Error500Path )->stringify );
                    } else {
                        $resp->Body( '<!DOCTYPE html><html><head><title>Error</title></head><body><h1>Internal Server Error</h1><p>Sorry, the page you are looking for is currently unavailable.<br/>Please try again later.</p></body></html>' );
                        $resp->ContentType( 'text/html' );
                    }
                }

            # Plasp error due to error in Plasp code. $asp and $Response is not
            # reliable. This implies a bug in Plasp.
            } else {
                Plasp->log->fatal( "Plasp error: $_" );

                $status = 500;
                $body   = sprintf '<!DOCTYPE html><html><head><title>Error</title></head><body><h1>Internal Server Error</h1>%s</body></html>', $class->config->{Debug} ? "<pre>$_</pre>" : '';
                push @headers, 'Content-Type' => 'text/html' unless grep { /Content-Type/ } @headers;
            }
        } finally {
            if ( $_asp ) {
                # Process the resulting response
                my $resp = $_asp->Response;
                $status  = $resp->Status || 200;
                $body    = $resp->Body;

                # Process the response headers
                # Set Content-Type header
                my $content_type = $resp->ContentType;
                my $charset      = $resp->Charset;
                if ( $charset ) {
                    $content_type .= "; charset=$charset";
                    $body = Encode::encode( $charset, $body );
                } elsif ( $content_type =~ /text|javascript|json/ ) {
                    $body = Encode::encode( 'UTF-8', $body );
                }
                push @headers, 'Content-Type' => $content_type;

                # Set the Cookies
                push @headers, @{ $resp->CookiesHeaders };

                # Set the Cache-Control
                push @headers, Cache_Control => $resp->CacheControl;

                # Set the Expires header from either Expires or ExpiresAbsolute
                # attribute
                if ( $resp->Expires ) {
                    push @headers, Expires => time2str( time + $resp->Expires );
                } elsif ( $resp->ExpiresAbsolute ) {
                    push @headers, Expires => $resp->ExpiresAbsolute;
                }

                # Add any custom headers from the application
                push @headers, @{ $resp->_headers };

                # Ensure destruction!
                $_asp->cleanup;
            }
        };

        return [ $status, \@headers, [ $body ] ]
    }
}

# Setup a session store global variable, to be created upon load
my $_session_tmp_dir = tempdir( "/tmp/plasp-sess-$$-XXXXXX", CLEANUP => 1 );
sub session_tmp_dir { return $_session_tmp_dir }

1;

=back

=head1 SEE ALSO

=over

=item * L<Plasp>

=back

1;
