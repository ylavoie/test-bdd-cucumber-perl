package Test::BDD::Cucumber::Model::Line::Step;
use Moose;

extends 'Test::BDD::Cucumber::Model::Line::Base';

sub has_children { 0 }
sub is_child { 1 }

1;