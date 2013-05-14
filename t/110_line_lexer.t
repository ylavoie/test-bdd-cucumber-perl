#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::Parser::Line;

my @lex_tests = (
	[
		"I've added \"<data>\" to the object # Blah",
		[ TEXT => "I've" ],
		[ SPACE => ' ' ],
		[ TEXT => 'added' ],
		[ SPACE => ' ' ],
		[ QUOTE => '"' ],
		[ PLACE_OPEN => '<' ],
		[ TEXT => 'data' ],
		[ PLACE_CLOSE => '>' ],
		[ QUOTE => '"' ],
		[ SPACE => ' ' ],
		[ TEXT => 'to' ],
		[ SPACE => ' ' ],
		[ TEXT => 'the' ],
		[ SPACE => ' ' ],
		[ TEXT => 'object' ],
		[ SPACE => ' ' ],
		[ COMMENT => 'Blah' ],
	]
);

for my $test ( @lex_tests ) {
	my $input = shift( @$test );
	my @tokens = Test::BDD::Cucumber::Parser::Line->lex( $input );
	is_deeply( \@tokens, $test, "Tokens match" );
}

done_testing();