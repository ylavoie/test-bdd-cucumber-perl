package t::lib::BuildLexer;

use strict;
use warnings;
use Data::Dumper;

our $location = 'grammar/lines.csv';
our $marker = '### LEXING RULES';
our $class = 'lib/Test/BDD/Cucumber/Parser/LineLexer.pm';

sub new_content {
	my $rules = serialize_rules(read_rules());
	my ($before, $x, $after) = get_parts();
	return
		"$before$marker\n$rules\n" .
		'our %STATE_MACHINE = %$STATE_MACHINE1;' . "\n" .
		"$marker$after";
}

sub get_parts {
	open( my $fh, '<', $class ) || die $!;
	my $content = join '', <$fh>;

	my ($before, $rules, $after) = split( /$marker/, $content );
	return $before, $rules, $after;
}

sub read_rules {
	local $/ = "\r";

	# File stuff
	open( my $fh, '<', $location ) || die $!;
	my @lines = <$fh>;
	close $fh;
	shift(@lines);

	my %rules;
	for my $line ( @lines ) {
		chomp $line;
		my ( $old, $type, $new, $re ) = split(/,/, $line);
		my $bla = $rules{ $old } //= [];
		push( $bla, {
			new_state => $new,
			match_on  => $re,
			type      => $type,
		})
	}

	return \%rules;
}

sub serialize_rules {
	my $rules = shift;
	local $Data::Dumper::Indent = 0;
	local $Data::Dumper::Varname = 'STATE_MACHINE';
	return Dumper( $rules );
}

1;