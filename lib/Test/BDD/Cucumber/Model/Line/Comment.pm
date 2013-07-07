package Test::BDD::Cucumber::Model::Line::Comment;
use Moose;

extends 'Test::BDD::Cucumber::Model::Line::Base';

# Can be ignored when building features and scenarios
sub inactive { 1 }

1;