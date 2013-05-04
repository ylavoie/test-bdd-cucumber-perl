#!perl

use strict;
use warnings;
use Test::BDD::Cucumber::Util;
use Test::BDD::Cucumber::Lexer;

my $feature = join '', (<STDIN>);

# Create the lexer, and get the tokens
my $lexer = Test::BDD::Cucumber::Lexer->new({
    source => $file,
    input => $input,
    input_original => $input,
});

my $tokens = join "\n", map {
        sprintf("%s[%s]",
            $_->{'type'},
            Test::BDD::Cucumber::Util::escape_whitespace( $_->{'text'} ) );
    } $lexer->all_tokens;

