package Test::BDD::Cucumber::Model::Token;
use Moose;

has 'type' => ( is => 'ro', isa => 'Str', required => 1 );
has 'raw'  => ( is => 'ro', isa => 'Str', required => 1 );
has 'text' => ( is => 'ro', isa => 'Str', required => 1 );

1;