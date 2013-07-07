package Test::BDD::Cucumber::Model::Line::HasChildren;
use Moose;
extends 'Test::BDD::Cucumber::Model::Line::Base';

use Test::BDD::Cucumber::Model::Feature;


sub model_name   { die "Override this method with a classname for to_model" }
sub extra_fields { die "Override this method with extra args for instantiation"}

sub has_children { 1 }
sub is_child     { 0 }

sub name {
    my $self = shift;
    my $name_token = $self->tokens->[1];
    $name_token ? $name_token->text() : '';
}

sub to_model {
    my $self = shift;
    my $model_class = $self->model_name;

    my $model = $model_class->new({
        name => $self->name,
        line => $self,
        $self->extra_fields()
    });

    return $model;
}

1;