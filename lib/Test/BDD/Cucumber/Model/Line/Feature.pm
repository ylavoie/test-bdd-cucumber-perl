package Test::BDD::Cucumber::Model::Line::Feature;

use Moose;
extends 'Test::BDD::Cucumber::Model::Line::HasChildren';

use Test::BDD::Cucumber::Model::Feature;


sub model_name   { return 'Test::BDD::Cucumber::Model::Feature'; }
sub extra_fields { return () }

1;