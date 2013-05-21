#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::Parser::Line;

my @parse_tests = (
	[ Background => " # That's some fun",
		[ COMMENT => "That's some fun" ],
	],
	[ Feature => 'Si\\\\mple "tests" <of> Digest.pm # Digest',
		[ TEXT => 'Si\\mple "tests" <of> Digest.pm' ],
		[ COMMENT => 'Digest' ],
	],
	[ Space => "\t \t",
		[ SPACE => "\t \t" ],
	],
	[ Comment => 'Si\\\\mple "tests" <of> Digest.pm',
		[ COMMENT => 'Si\\mple "tests" <of> Digest.pm' ],
	],
	[ Tag => '@Si\\\\mple @"tests" @<o@f> # Digest.pm',
		[ TAG => 'Si\\mple' ],
		[ TAG => '"tests"' ],
		[ TAG => '<o@f>' ],
		[ COMMENT => 'Digest.pm' ],
	],
	[ COS => 'Si\\\\mple "tests" <of> Digest.pm # Digest',
		[ TEXT => 'Si\\mple "tests" <of> Digest.pm' ],
		[ COMMENT => 'Digest' ],
	],
	[ Step => 'Then "<number big>" <2 and > 5 @the moment # Comment',
		[ TEXT  => 'Then ' ],
		[ QUOTE => '"' ],
		[ PLACEHOLDER => 'number big' ],
		[ QUOTE => '"' ],
		[ TEXT => ' <2 and > 5 @the moment' ],
		[ COMMENT => 'Comment' ],
	],
	[ Example => " # That's some fun",
		[ COMMENT => "That's some fun" ],
	],
	[ Table => "  |  1|2 | 3 |\\||\"@ <asdf> || |    #| fasd",
		[ CELL => "1" ],
		[ CELL => "2" ],
		[ CELL => "3" ],
		[ CELL => "|" ],
		[ CELL => '"@ <asdf>' ],
		[ CELL => "" ],
		[ CELL => "" ],
		[ COMMENT => "| fasd" ],
	],

	#PyMark
	#Quoted
);

for my $test ( @parse_tests ) {
	my ( $type, $input, @expected ) = @$test;
	my @tokens = Test::BDD::Cucumber::Parser::Line->parse( $type, $input );
	is_deeply( \@tokens, \@expected, "Tokens match for $type" );
}


done_testing();