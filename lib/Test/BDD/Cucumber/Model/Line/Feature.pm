package Test::BDD::Cucumber::Model::Line::Space;
use Moose;

extends 'Test::BDD::Cucumber::Model::Line::Base';

has name => ( is => 'ro', isa => 'Str', lazy => 1 );
has keyword => ( is => 'ro', isa => 'Str', lazy => 1, builder => 'first_match' );

sub _build_name {
1
}

1;