package Test::BDD::Cucumber::Model::Line::Background;
use Moose;
use Test::BDD::Cucumber::Model::Scenario;

extends 'Test::BDD::Cucumber::Model::Line::HasChildren';

sub model_name   { return 'Test::BDD::Cucumber::Model::Scenario'; }
sub extra_fields { return ( background => 1 ) }

1;