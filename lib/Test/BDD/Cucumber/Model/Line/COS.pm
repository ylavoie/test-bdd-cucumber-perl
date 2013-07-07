package Test::BDD::Cucumber::Model::Line::COS;
use Moose;

extends 'Test::BDD::Cucumber::Model::Line::Base';

sub has_children { 0 }
sub is_child { 1 }

sub text {
    my $self = shift;
    return $self->tokens->[0]->text;
}

1;