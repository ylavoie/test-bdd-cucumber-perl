package Test::BDD::Cucumber::Model::Line::Base;
use Moose;

has 'tokens'   => ( is => 'ro', isa => 'ArrayRef', required => 1 );



#has 'line_number' => ( is => 'ro', isa => 'Int', default => -1 );
has 'content'  => ( is => 'ro', isa => 'Str', required => 1 );
#has 'matched'  => ( is => 'ro', isa => 'ArrayRef[Str]' );
#has 'stripped' => ( is => 'ro', isa => 'Str', lazy => 1 );
#has 'tokens'   => ( is => 'ro', isa => 'ArrayRef', required => 1 );

# sub _build_stripped {
# 	my $self = shift;
# 	my $content = $self->content;
# 	$content =~ s/^\s+//;
# 	$content =~ s/\s+$//;
# 	return $content;
# }

# sub first_match {
# 	my $self = shift;
# 	return $self->matched->[0];
# }

sub type {
    my $self = shift;
    my $name = ref $self;
    $name =~ s/.+:://;
    return $name;
}

1;