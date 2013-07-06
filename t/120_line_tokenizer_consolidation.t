#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::Parser::Tokenize;

my @parse_tests = (
	[ Background => "  Background:  # That's some fun",
		[ KEYWORD => 'Background', 'Background:  ' ],
		[ COMMENT => "That's some fun", "# That's some fun" ],
	],
	[ Feature => '      Feature: Si\\\\mple "tests" <of> Digest.pm # Digest',
		[ KEYWORD => 'Feature', 'Feature: ' ],
	 	[ TEXT => 'Si\\mple "tests" <of> Digest.pm' ],
	 	[ COMMENT => 'Digest', ' # Digest' ],
	],
	[ Scenario => 'Scenario: Si\\\\mple "tests" <of> Digest.pm # Digest',
		[ KEYWORD => 'Scenario', 'Scenario: ' ],
	 	[ TEXT => 'Si\\mple "tests" <of> Digest.pm' ],
	 	[ COMMENT => 'Digest', ' # Digest' ],
	],
	[ Space => "\t \t",
	 	[ SPACE => "\t \t" ],
	],
	[ Comment => '# Si\\mple "tests" <of> Digest.pm',
	 	[ COMMENT =>
	 		'Si\\mple "tests" <of> Digest.pm',
	 		'# Si\\mple "tests" <of> Digest.pm' ],
	],
	[ Tag => '@Si\\\\mple @"tests" @<o@f> # Digest.pm',
	 	[ TAG => 'Si\\mple', '@Si\\mple' ],
	 	[ TAG => '"tests"', '@"tests"' ],
	 	[ TAG => '<o@f>', '@<o@f>' ],
	 	[ COMMENT => 'Digest.pm', ' # Digest.pm' ],
	],
	[ COS => 'Si\\\\mple "tests" <of> Digest.pm # Digest',
	 	[ TEXT => 'Si\\mple "tests" <of> Digest.pm' ],
	 	[ COMMENT => 'Digest', ' # Digest' ],
	],
	[ Step => '  Then "<number big>" <2 and > 5 @the moment # Comment',
	 	[ KEYWORD => 'Then', 'Then ' ],
	 	[ QUOTE => '"' ],
	 	[ PLACEHOLDER => 'number big', '<number big>' ],
	 	[ QUOTE => '"' ],
	 	[ TEXT => ' <2 and > 5 @the moment' ],
	 	[ COMMENT => 'Comment', ' # Comment' ],
	],
	[ Examples => "Examples: # That's some fun",
		[ KEYWORD => 'Examples', 'Examples: '],
	 	[ COMMENT => "That's some fun", "# That's some fun" ],
	],
	[ Table => "  |  1|2 | 3 |\\||\"@ <asdf> || |    #| fasd",
	 	[ CELL => "1", '  1' ],
	 	[ CELL => "2", '2 '  ],
	 	[ CELL => "3", ' 3 ' ],
	 	[ CELL => "|", '|'   ],
	 	[ CELL => '"@ <asdf>', '"@ <asdf> ' ],
	 	[ CELL => "", ''  ],
	 	[ CELL => "", ' ' ],
	 	[ COMMENT => "| fasd", "    #| fasd" ],
	],
	[ PyMark => '   """    ',
	 	[ SPACE => '   '  ],
	 	[ PYMARK => '"""' ],
	],
	[ Quoted => '  Si\\\\mple "tests" <of> Digest.pm # Digest',
		[ SPACE => '  ' ],
	 	[ TEXT => 'Si\\mple "tests" <of> Digest.pm # Digest' ],
	]
);

for my $test ( @parse_tests ) {
	my ( $type, $input, @expected ) = @$test;
	my @tokens = Test::BDD::Cucumber::Parser::Tokenize->parse({
		line_type => $type,
		content => $input
	});

	@expected = map {
		Test::BDD::Cucumber::Model::Token->new({
			type => $_->[0],
			text => $_->[1],
			raw  => $_->[2] || $_->[1],
		})
	} @expected;

	is_deeply( \@tokens, \@expected, "Tokens match for $type" );
}


done_testing();