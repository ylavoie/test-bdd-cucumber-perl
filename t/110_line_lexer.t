#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::Parser::LineLexer;
use Data::Dumper;

my @lines = <DATA>;
my $feature  = join '', map { my $l = $_; $l =~ s/^.+?\|//; $l } @lines;
my @expected = map { m/^(\w+)/; $1 } @lines;

my @objects = Test::BDD::Cucumber::Parser::LineLexer->parse({
	content  => $feature,
	language => bless {}, 'Test::BDD::Cucumber::Language'
});

my $line = 1;

for my $object (@objects) {
	my $expected = shift @expected;

	my $received_class = ref $object;
	$received_class =~ s/.+:://;

	is( $received_class, $expected, $line++ . " matched $expected" ) ||
		die Dumper $object;
}

done_testing();

__DATA__
Comment   | # Somehow I don't see this replacing the other tests this module has...
Feature   | Feature: Simple tests of Digest.pm
COS       |  As a developer planning to use Digest.pm
COS       |  I want to test the basic functionality of Digest.pm
COS       |  In order to have confidence in it
Space     |
Background|  Background:
Step      |    Given a usable "Digest" class
Space     |
Tag       |  @Some @tag @goes @HERE # OK
Scenario  |  Scenario: Check MD5
Step      |    Given a Digest MD5 object
Step      |    When I've added "foo bar baz" to the object
Step      |    And I've added "bat ban shan" to the object
Step      |    Then the hex output is "bcb56b3dd4674d5d7459c95e4c8a41d5"
Step      |    Then the base64 output is "1B2M2Y8AsgTpgAmY7PhCfg"
Space     |
Scenario  |  Scenario: Check SHA-1
Step      |    Given a Digest SHA-1 object
Step      |    When I've added "<data>" to the object
Step      |    Then the hex output is "<output>"
Examples  |    Examples:
Table     |      | data | output   |
Table     |      | foo  | 0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33 |
Table     |      | bar  | 62cdb7020ff920e5aa642c3d4066950dd1f01f4d |
Table     |      | baz  | bbe960a25ea311d21d40669e93df2003ba9b90a2 |
Space     |
Scenario  |  Scenario: MD5 longer data
Step      |    Given a Digest MD5 object
Step      |    When I've added the following to the object
PyMark    |      """
Quoted    |      Here is a chunk of text that works a bit like a HereDoc. We'll split
Quoted    |      off indenting space from the lines in it up to the indentation of the
Quoted    |      first \"\"\"
PyMark    |      """
Step      |    Then the hex output is "75ad9f578e43b863590fae52d5d19ce6"
Space     |
Space     |