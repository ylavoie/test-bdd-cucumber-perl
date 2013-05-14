#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::Parser::Line;

my @parse_tests = (
	[ Background => " # That's some fun",
		[ COMMENT => "That's some fun" ],
	],
	[ Feature => 'Si\\\\mple "tests" <of> Digest.pm',
		[ TEXT => 'Si\\mple "tests" <of> Digest.pm' ],
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
);

for my $test ( @parse_tests ) {
	my ( $type, $input, @expected ) = @$test;
	my @tokens = Test::BDD::Cucumber::Parser::Line->parse( $type, $input );
	is_deeply( \@tokens, \@expected, "Tokens match for $type" );
}

done_testing();