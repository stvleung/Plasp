package Plasp::Log;

use strict;

=head1 NAME

Plasp::Log - Logging class for Plasp

=head1 SYNOPSIS

  package Plasp;

  has 'log' => (
    default => { Plasp::Log->new }
  );

  1;

=head1 DESCRIPTION

A class to define logger functions. Essentially send every message to STDERR,
although prepends log level

=head1 METHODS

=over

=item $class->new()

Returns a blessed array ref, able to push log messages into

=cut

sub new { return bless [], shift }

=item $log->debug( @messages )

Add debug log messages into log and prints to STDERR

=cut

sub debug {
    my $self = shift;
    my @messages = map { "[DEBUG] $_" } @_;
    push @$self, @messages;
    print STDERR @messages;
}

=item $log->info( @messages )

Add info log messages into log and prints to STDERR

=cut

sub info {
    my $self = shift;
    my @messages = map { "[INFO] $_" } @_;
    push @$self, @messages;
    print STDERR @messages;
}

=item $log->warn( @messages )

Add warn log messages into log and prints to STDERR

=cut

sub warn {
    my $self = shift;
    my @messages = map { "[WARN] $_" } @_;
    push @$self, @messages;
    print STDERR @messages;
}

=item $log->error( @messages )

Add error log messages into log and prints to STDERR

=cut

sub error {
    my $self = shift;
    my @messages = map { "[ERROR] $_" } @_;
    push @$self, @messages;
    print STDERR @messages;
}

1;

=back
