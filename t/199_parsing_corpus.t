#!perl

use strict;
use warnings;
use Test::BDD::Cucumber::Lexer;
use File::Slurp qw/read_file/;
use Test::More;
use Test::Differences;
use File::Find::Rule;

my @files = @ARGV;
@files = sort File::Find::Rule
    ->file()->name( '*.corpus' )->in( 't/parsing_corpus/' )
    unless @files;

for my $file ( @files ) {

    # Get the file contents
    my $file_data = read_file( $file );
    my ( $token_stream, $input ) = split(/\n__DIVIDER__\n/, $file_data);

    # Create the lexer, and get the tokens
    my $lexer = Test::BDD::Cucumber::Lexer->new({
        source => $file,
        input => $input,
        input_original => $input,
    });
    my @received_tokens = map {
            [ $_->{'type'}, $_->{'text'} ]
        } $lexer->tokens;

    # Read in the token stream
    my @expected_tokens = map {
            if ( $_ =~ m/^([A-Z_]+)\[(.*)\]/ ) {
                [ $1, $2 ];
            } else {
                ();
            }
        } split(/\n/, $token_stream);

    eq_or_diff( \@received_tokens, \@expected_tokens, $file );
}

done_testing();
