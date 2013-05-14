package Test::BDD::Cucumber::Model::Line::Base;
use Moose;

has 'content'  => ( is => 'ro', isa => 'Str', required => 1 );
has 'matched'  => ( is => 'ro', isa => 'ArrayRef[Str]' );
has 'stripped' => ( is => 'ro', isa => 'Str', lazy => 1 );

sub _build_stripped {
	my $self = shift;
	my $content = $self->content;
	$content =~ s/^\s+//;
	$content =~ s/\s+$//;
	return $content;
}

sub first_match {
	my $self = shift;
	return $self->matched->[0];
}

1;