#!perl

use strict;
use warnings;
use Test::More;

use Test::BDD::Cucumber::Model::Token;
use Test::BDD::Cucumber::Parser::Tokenize;

# Simple test of _lex()
my @dumb_tokens = Test::BDD::Cucumber::Parser::Tokenize->_lex(
    'Feature: I "am" <here> #ok '
);

is_deeply(
    \@dumb_tokens,
    [
        [ KEYWORD => 'Feature: ' ],
        [ TEXT    => 'I'  ],
        [ SPACE   => ' '  ],
        [ QUOTE   => '"'  ],
        [ TEXT    => 'am' ],
        [ QUOTE   => '"'  ],
        [ SPACE   => ' '  ],
        [ PLACE_OPEN => '<' ],
        [ TEXT    => 'here' ],
        [ PLACE_CLOSE => '>' ],
        [ COMMENT => ' #ok '],
    ],
    "_lex() works"
);


# Simple(!) consolidation
my @cleaned = Test::BDD::Cucumber::Parser::Tokenize->_consolidate(
    Feature => @dumb_tokens,
);

is_deeply(
    \@cleaned,
    [
        [ KEYWORD => 'Feature: ' ],
        [ TEXT    => 'I "am" <here>' ],
        [ COMMENT => ' #ok ' ],
    ],
    "_consolidate works",
);

# Simple test of cleanup
my @objects = Test::BDD::Cucumber::Parser::Tokenize->_clean_and_instantiate(
    [ KEYWORD => 'Feature: ' ],
    [ PLACEHOLDER => "<MOE>" ],
    [ COMMENT => ' #ok '],
);
is_deeply(
    \@objects,
    [map {
        Test::BDD::Cucumber::Model::Token->new({
            type => $_->[0],
            text => $_->[1],
            raw  => $_->[2],
        })
    } (
        [ KEYWORD => Feature => 'Feature: ' ],
        [ PLACEHOLDER => MOE => '<MOE>' ],
        [ COMMENT => ok => ' #ok ' ],
    )],
    "_clean_and_instantiate() works"
);


done_testing();
