package Test::BDD::Cucumber::Parser::Error;

use Moose;
extends 'Throwable::Error';

has line_number => ( is => 'ro', isa => 'Int' );
has state       => ( is => 'ro', isa => 'Str' );
has content     => ( is => 'ro', isa => 'Str' );

sub as_string {
	my $self = shift;
	sprintf(
		"> Line:%2d: [%s]\n> Parser state: %s\n> Error: %s\n---\n%s",
		$self->line_number, $self->content, $self->state,
		$self->message, $self->stack_trace
	);
}

1;