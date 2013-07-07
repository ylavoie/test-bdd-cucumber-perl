package Test::BDD::Cucumber::Model::Line::Base;
use Moose;

has 'number'      => ( is => 'ro', isa => 'Int', required => 1 );
has 'raw_content' => ( is => 'ro', isa => 'Str', required => 1 );
has 'tokens'      => ( is => 'ro', isa => 'ArrayRef', required => 1 );

# Default is that we have to care about lines
sub inactive { 0 }

sub has_children { 0 }
sub is_child { 0 }

sub type {
    my $self = shift;
    my $name = ref $self;
    $name =~ s/.+:://;
    return $name;
}

1;