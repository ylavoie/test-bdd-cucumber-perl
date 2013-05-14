package Test::BDD::Cucumber::Parser::Error;

use Moose;
extends 'Throwable::Error';

sub simple_message {
	my $self = shift;
	use Data::Dumper; print Dumper($self);
	exit;
	return $self->message . "\t" . $self->stack_trace->as_string . "\n"
}

sub stack_list {
	my $self = shift;

	# Get the parent node
	my $parent = $self->previous_exception();

	# Base case
	return $self->simple_message unless $parent;
	# Non-object parent error
	return ($parent, $self->simple_message) unless
		( ref $parent && $parent->can('simple_message') );
	# Recurse
	return ($parent->stack_list, $self->simple_message);
}

sub as_string {
	my $self = shift;
	return join "\n---\n", ("Parser error", $self->stack_list);
}

1;