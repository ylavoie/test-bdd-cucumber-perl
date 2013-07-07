package Test::BDD::Cucumber::Model::Line::Tag;
use Moose;

extends 'Test::BDD::Cucumber::Model::Line::Base';

sub has_children { 0 }
sub is_child { 0 }

sub tags {
    my $self = shift;
    return map { $_->text } @{$self->tokens};
}

1;