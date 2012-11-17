package Test::BDD::Cucumber::Lexer;

use strict;
use warnings;

=head1 NAME

Test::BDD::Cucumber::Lexer - Turns a Model::Document object in to commands

=head1 DESCRIPTION

Parses lines in a cucumber file in to commands

=head1 SYNOPSIS

 my @commands = Test::BDD::Cucumber::Lexer->parse({
 	document => Test::BDD::Cucumber::Model::Document object,
 	language => 'en' # en is default
 });

=head1 OVERVIEW

Conceptually by the time we have a Document object, we have split up either
a filename or a string in to lines, and created a line to represent that. We've
also done any encoding.

Thus: we've turned a document the user has told us about in to a document we
are able to understand (and work with) in terms of lines and the origin of those
lines.

We haven't yet made any decision about what those lines mean. That's what this
Lexer does - it works out what each line means, sometimes using context about
it. It doesn't use the information about what each line means to build up
Features and Scenarios - that's the job of the parser.

=head1 METHODS

=head2 parse

Accepts a hashref with a C<document>, a L<Test::BDD::Cucumber::Model::Document>
object, and C<language>, which needs to correspond to a language in the included
C<i18n.yml> file, and returns a series of C<commands>.

=cut

use constant $MODE_GENERAL      => 0;
use constant $MODE_SATISFACTION => 1;
use constant $MODE_PYSTRING     => 2;

sub parse {
	my ( $class, $opts ) = @_;
	my @lines = @{$opts->{'document'}->lines};

	my @commands;
	my $mode = $MODE_GENERAL;

	for my $line (@lines) {
		my ( $new_mode, $command ) = $class->_parse_line(
			$mode, $line
		);
		$mode = $new_mode;
		push( @commands, $command );
	}

	return @commands;
}

__DATA__

  name: English
  native: English
  feature: Feature
  background: Background
  scenario: Scenario
  scenario_outline: Scenario Outline|Scenario Template
  examples: Examples|Scenarios
  given: "*|Given"
  when: "*|When"
  then: "*|Then"
  and: "*|And"
  but: "*|But"
