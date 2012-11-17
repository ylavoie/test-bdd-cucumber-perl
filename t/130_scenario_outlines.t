#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::Parser;

# Begin rant...
#
# There are at least three valid ways of doing scenario outlines in Gherkin.
# When I got started, I implemented the most sensible one, but really we need
# to support them all, which is a shame.
# I've brought together some examples here that are listed as valid elsewhere on
# the internets, and hopefully this is all ok...

my $feature = Test::BDD::Cucumber::Parser->parse_string(
<<HEREDOC
Feature: Test Feature
	Crazy-ass scenario-outline testing.

    Scenario Outline: eating
        Given there are <start> cucumbers
        When I eat <eat> cucumbers
        Then I should have <left> cucumbers

        Examples:
          | start | eat | left |
          |  12   |  5  |  7   |
          |  20   |  5  |  15  |

    Scenario Outline: score should be as per the std rules
        Given I am starting a new game
        When my rolls are <rolls>
        Then the score should be <score>
        Scenarios: lets go bowling
          | rolls   | score |
          |5 2      | 7     |
          |5 5 5    | 15    |

HEREDOC
);

use Data::Printer;
p $feature;

done_testing;