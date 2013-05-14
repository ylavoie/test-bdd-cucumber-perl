package Test::BDD::Cucumber::Parser::Line;

use strict;
use warnings;

our @TOKENS = (
	[ TEXT        => qr/^\\(.)/ ], # Escapes
	[ COMMENT     => qr/^# ?(.*)/ ],
	[ QUOTE       => qr/^(")/   ],
	[ TAG         => qr/^(\@)/  ],
	[ PLACE_OPEN  => qr/^(\<)/  ],
	[ PLACE_CLOSE => qr/^(\>)/  ],
	[ SPACE       => qr/^(\s+)/ ],
	[ COLON       => qr/^(\:)/  ],
	[ PIPE        => qr/^(\|)/  ],
	[ TEXT        => qr/^([^\\#"\<\>\s\:\|]+)/ ],
);

sub _only {
	my @allowed = @_;
	my %allowed = map { $_ => 1 } @allowed;

	return sub {
		my @bad_tokens = grep {! $allowed{$_->[0]} } @_;
		if ( @bad_tokens ) {
			die "Unexpected content: " . join ' ', map { $_->[1] } @bad_tokens
		}
		return @_;
	}
}

sub _convert_to {
	my ($to, @except) = @_;
	my %except = map { $_ => 1 } @except;

	return sub {
		map {
			my ( $type, $payload ) = @$_;
			if ( $except{$type} ) {
				$_;
			} else {
				[ $to => $payload ]
			}
		} @_;
	};
}

# Really these are rules and filters
our %RULES = (
	# Throws an error if there are any tokens other than COMMENTS
	COMMENTS_ONLY => _only('COMMENT'),

	# Combines all adjacent TEXT tokens
	COMBINE_TEXT => sub {
		my ( $first, @old_tokens ) = @_;
		my @new_tokens = ($first);

		while (my $token = shift @old_tokens) {
			if ( $token->[0] eq 'TEXT' ) {
				if ( $new_tokens[-1]->[0] eq 'TEXT' ) {
					$new_tokens[-1]->[1] .= $token->[1]
				} else {
					push( @new_tokens, $token );
				}
			} else {
				push( @new_tokens, $token );
			}
		}

		return @new_tokens;
	},

	# Tokens by this point should be (TAG TEXT SPACE?)+ COMMENT?
	MAKE_TAGS => sub {
		my @tokens = @_;

		# Remove and save a comment
		my @comments = ();
		if ($tokens[-1]->[0] eq 'COMMENT') {
			push( @comments, pop(@tokens) );
		}

		# If the final token isn't a space, make it one
		unless ( $tokens[-1]->[0] eq 'SPACE' ) {
			push( @tokens, [SPACE => ''] )
		}

		# Now we should have (TAG TEXT SPACE)+
		if ( @tokens % 3 ) {
			die "Unexpected number of tag tokens: " .
				join ';', map {sprintf"[%s|%s]",@$_} @tokens;
		}

		my @tags;
		while ( @tokens ) {
			my ( $mark, $text, $space ) =
				(shift(@tokens),shift(@tokens),shift(@tokens));
			die "Unexpected content: " . $mark->[1] . ':' . $mark->[1]
				unless $mark->[0] eq 'TAG';
			die "Unexpected content: " . $text->[1] . ':'  . $text->[1]
				unless $text->[0] eq 'TEXT';
			die "Unexpected content: "  . $space->[1] . ':' . $space->[1]
				unless $space->[0] eq 'SPACE';

			push( @tags, [ TAG => $text->[1] ] );
		}
		return @tags, @comments;
	},

	# Gets rid of all SPACE tokens
	REMOVE_SPACES => sub { grep { $_->[0] ne 'SPACE' } @_ },

	# All SPACE becomes single-space TEXT
	SPACE_TO_TEXT => sub {
		map {
			if ($_->[0] eq 'SPACE') {
				[ TEXT => ' ' ]
			} else {
				$_
			}

		} @_
	},

	TO_COMMENT => _convert_to('COMMENT'),
	TO_TEXT    => _convert_to('TEXT'),
	TO_TEXT_AND_COMMENTS => _convert_to('TEXT', 'COMMENT'),

	# Tags...
	TO_TAGS => _convert_to('TEXT', qw/COMMENT TAG SPACE/),
);

our %TYPES = (
	Background => filter(qw/REMOVE_SPACES COMMENTS_ONLY/),
	Comment    => filter(qw/TO_TEXT COMBINE_TEXT TO_COMMENT/),
	# Changes everything except comments in to text
	Feature    => filter(qw/TO_TEXT_AND_COMMENTS COMBINE_TEXT/),
	Space      => sub { @_ },
	Tag        => filter(qw/TO_TAGS COMBINE_TEXT MAKE_TAGS/),
);

# Subref composition, whoop whoop
sub compose {
	# Do we have arguments left to compose?
	@_ ?
		# A sub that composes two subs
        sub {
            my( $f, $g ) = @_;
			sub { $g->($f->(@_) ) }

        # Applied to
		}->(
            shift( @_ ),  # Head
            compose( @_ ) # And a function composed of the tail, composed
        )

    # The base case is the `id`
    : sub {@_}
}

sub filter {compose( map { $RULES{$_} } @_)}

sub parse {
	my ($class, $type, $input) = @_;
	return $TYPES{ $type }->( $class->lex( $input ) );
}

# Dumb tokens
sub lex {
	my ($class, $input) = @_;

	my @found;

	while ( length $input ) {
		for (@TOKENS) {
			my ( $type, $re ) = @$_;
			if ( $input =~ s/$re// ) {
				push(@found, [$type, $1] );
				last;
			}
		}
	}
	return @found;
}


__DATA__

# When I've added "<data>" to the object # Blah
# KEYWORD: When
# TEXT: I've added
# QUOTE: "
# PLACEHOLDER: data
# QUOTE: "
# TEXT: to the object

Background
Comment
COS
Examples
Feature
PyMark
Quoted
Scenario
Space
Step
Table
Tag

our %types = (
	ESCAPED => {
		re      =>
		combine => 1,
		gives   => 'TEXT',
	},
	COMMENT => {
		re    => qr/^# ?(.+)/,
		gives => 'TEXT',
	},
);

sub tokenize {
	my ( $input, @features ) = @_;

}

1;