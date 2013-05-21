package Test::BDD::Cucumber::Parser::LineLexer;

use strict;
use warnings;
use Test::BDD::Cucumber::Parser::Error;

=head1 NAME

Test::BDD::Cucumber::Parser::LineLexer - Quick-parse Gherkin

=head1 DESCRIPTION

Turns a string of Gherkin in to TBC::Model::Line objects

=head1 WARNING

Probably no user-serviceable parts here

=head1 SYNOPSIS

 my $document = Test::BDD::Cucumber::Parser::LineLexer->parse({
	content  => "",
	language => Test::BDD::Cucumber::Language object,
	line     => 0, # Default
 });

=head1 METHODS

=cut

# The below part is auto-generated from the lines.csv file as part of the build
# process... Don't hand-modify it!
### LEXING RULES
my $STATE_MACHINE1 = {'COS' => [{'new_state' => 'General','class' => 'Test::BDD::Cucumber::Model::Line::Background','type' => 'Background','match_on' => 'SCENARIO'},{'new_state' => 'General','class' => 'Test::BDD::Cucumber::Model::Line::Scenario','type' => 'Scenario','match_on' => 'SCENARIO'},{'new_state' => 'General','class' => 'Test::BDD::Cucumber::Model::Line::Tag','type' => 'Tag','match_on' => 'TAGS'},{'new_state' => 'COS','class' => 'Test::BDD::Cucumber::Model::Line::Comment','type' => 'Comment','match_on' => 'COMMENT'},{'new_state' => 'COS','class' => 'Test::BDD::Cucumber::Model::Line::Space','type' => 'Space','match_on' => 'BLANK'},{'new_state' => 'COS','class' => 'Test::BDD::Cucumber::Model::Line::COS','type' => 'COS','match_on' => 'ANY'}],'PyString' => [{'new_state' => 'General','class' => 'Test::BDD::Cucumber::Model::Line::PyMark','type' => 'PyMark','match_on' => 'PYMARK'},{'new_state' => 'PyString','class' => 'Test::BDD::Cucumber::Model::Line::Quoted','type' => 'Quoted','match_on' => 'ANY'}],'General' => [{'new_state' => 'General','class' => 'Test::BDD::Cucumber::Model::Line::Tag','type' => 'Tag','match_on' => 'TAGS'},{'new_state' => 'General','class' => 'Test::BDD::Cucumber::Model::Line::Scenario','type' => 'Scenario','match_on' => 'SCENARIO'},{'new_state' => 'General','class' => 'Test::BDD::Cucumber::Model::Line::Background','type' => 'Background','match_on' => 'BACKGROUND'},{'new_state' => 'General','class' => 'Test::BDD::Cucumber::Model::Line::Step','type' => 'Step','match_on' => 'STEP'},{'new_state' => 'General','class' => 'Test::BDD::Cucumber::Model::Line::Examples','type' => 'Examples','match_on' => 'EXAMPLES'},{'new_state' => 'General','class' => 'Test::BDD::Cucumber::Model::Line::Table','type' => 'Table','match_on' => 'TABLE'},{'new_state' => 'General','class' => 'Test::BDD::Cucumber::Model::Line::Comment','type' => 'Comment','match_on' => 'COMMENT'},{'new_state' => 'General','class' => 'Test::BDD::Cucumber::Model::Line::Space','type' => 'Space','match_on' => 'BLANK'},{'new_state' => 'PyString','class' => 'Test::BDD::Cucumber::Model::Line::PyMark','type' => 'PyMark','match_on' => 'PYMARK'}],'Start' => [{'new_state' => 'COS','class' => 'Test::BDD::Cucumber::Model::Line::Feature','type' => 'Feature','match_on' => 'FEATURE'},{'new_state' => 'Start','class' => 'Test::BDD::Cucumber::Model::Line::Space','type' => 'Space','match_on' => 'BLANK'},{'new_state' => 'Start','class' => 'Test::BDD::Cucumber::Model::Line::Comment','type' => 'Comment','match_on' => 'COMMENT'},{'new_state' => 'Start','class' => 'Test::BDD::Cucumber::Model::Line::Tag','type' => 'Tag','match_on' => 'TAGS'}]};
our %STATE_MACHINE = %$STATE_MACHINE1;
### LEXING RULES

# Need to pull in all of those classes
my %_classes;
for (map {@$_} values %STATE_MACHINE) {
	$_classes{$_->{'class'}}++;
}
for (keys %_classes) {
	eval "require $_";
}

=head2 parse

Accepts a string C<content> containing a well-formed Gherkin document, and
returns a list of L<Test::BDD::Cucumber::Model::Line> objects. Dies on malformed
input, with an error that relates to where in the input document the error was,
but explicitly hiding the fact that an error was generated here, which means
you MUST catch it, and consider wrapping it in a more sensible way.

=cut

sub parse {
	my ( $class, $options ) = @_;

	# Gotta have a parsing language
	die "You must provide an input language as a TBC::Language object" unless
		$options->{'language'} &&
		ref($options->{'language'}) eq "Test::BDD::Cucumber::Language";

	# Seed the state machine
	my $line_number = $options->{'line'} // 0;
	my $state       = $options->{'state'} // 'Start'; # Don't use this, k?

	# Don't need no speed
	my @lines = split(/(\r\n|\n|\r)/, $options->{'content'});

	# Where we store the parsed lines
	my @line_objects;

	LINE: for my $line ( @lines ) {
		# What are the options, given this state?
		my @options = @{ $STATE_MACHINE{ $state } };

		# Any of them actually match?
		for ( @options ) {
			my ( $re_name, $next, $name, $class ) =
				@$_{qw/match_on new_state type class/};
			my $re = _re($re_name);

			if ( my @matches = ($line =~ $re) ) {

				# Attempt to create the line object
				my $object = $class->new({
					content => $line,
					matched => \@matches,
				});
				# if ( $@ ) {
				# 	Test::BDD::Cucumber::Parser::Error->throw({
				# 		line_number => $line_number,
				# 		state       => $state,
				# 		content     => $line,
				# 		message     => sprintf(
				# 			"Line matched \"%s\" %s but couldn't create a %s object via %s",
				# 			$re_name, $re, $name, $class )
				# 	});
				# }

				# Assuming that worked, save it, update the current line and
				# state, and move to the next line
				push( @line_objects, $object );
				$line_number++;
				$state = $next;
				next LINE;
			}
		}

		# If we didn't hit that, then none of our options matched :-/
		# Test::BDD::Cucumber::Parser::Error->throw({
		# 	line_number => $line_number,
		# 	state       => $state,
		# 	content     => $line,
		# 	message     =>

		die sprintf(
				"Parser in state [%s] couldn't match any of the allowed line types, which are: [%s]",
				$state, join( ';', map { $_->[2] } @options )
		);

	}

	return @line_objects;
}

our %LINE_RE = (
	ANY        => qr/^.*$/,
	BACKGROUND => qr/^\s*Background: /i,
	BLANK      => qr/^\s*$/,
	COMMENT    => qr/^\s*#.*/,
	EXAMPLE    => qr/^\s*Examples:/i,
	FEATURE    => qr/^\s*Feature: /i,
	PYMARK     => qr/^\s*"""/i,
	SCENARIO   => qr/^\s*Scenario: /i,
	STEP       => qr/^\s*(Given|When|Then|But|And|\*) /i,
	TABLE      => qr/^\s*\|/,
	TAGS       => qr/^\s*@/,
);

sub _re { return $LINE_RE{$_[0]}; }
