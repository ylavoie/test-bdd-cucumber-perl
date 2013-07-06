package Test::BDD::Cucumber::Parser::Line;

use strict;
use warnings;

# Parser states that we'll localize for diag
our $line_type;

our @TOKENS = (
	[ TEXT        => qr/^\\(.)/ ], # Escapes
	[ COMMENT     => qr/^\s*(# ?.*)/ ],
	[ PYMARK      => qr/^(""")/ ],
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
		my @tokens = @_;
		my @ok;

		for my $token (@tokens) {
			unless ( $allowed{$token->[0]} ) {
				die sprintf(
					"Parser error while tokenizing a %s line:\n" .
					"  After: [%s]" .
					"  Found: [%s], type [%s]" .
					"which isn't allowed here\n",
					$line_type,
					(join '', map { $_->[1] } @ok),
					$token->[1], $token->[0],
				);
			};
			push( @ok, $token );
		}
		return @ok;
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

	PLACEHOLDERS => sub {
		my @tokens = @_;
		my @new_tokens;

		while ( @tokens ) {
			my $token = shift( @tokens );
			my ($type, $payload) = @$token;
			# OK, let's see how this pans out...
			if ($type eq 'PLACE_OPEN') {
				# It's only possible if we're followed directly by TEXT
				# One example of that /not/ being true is if we're out of
				# @tokens!
				unless (@tokens) {
					push( @new_tokens, $token );
					next;
				}

				# Another example of that is if the next token isn't actually
				# TEXT
				my $next = shift(@tokens);
				unless ( $next->[0] eq 'TEXT' ) {
					push( @new_tokens, ( $token, $next ) );
					next;
				}

				# From here on out, we're happy to accept spaces or text...
				my @token_text = $next;
				while ( 1 ) {
					my $this = shift(@tokens);
					# If we've run out of tokens, that's all folks
					unless ( defined $this ) {
						push( @new_tokens, ( $token, @token_text ) );
						last;
					}

					# If it's text or space, that's simple, keep going
					if ( $this->[0] eq 'TEXT' || $this->[0] eq 'SPACE' ) {
						push( @token_text, $this );
						next;

					# If it's a terminator, we're happy... as long as the last
					# token was text
					} elsif (
						$this->[0] eq 'PLACE_CLOSE' &&
						$token_text[-1]->[0] eq 'TEXT'
					) {
						# Add a placeholder to the token queue, and then
						# break out of this loop
						my ($as_text) = filter(qw/TO_TEXT COMBINE_TEXT/)
							->( @token_text );
						$as_text->[0] = 'PLACEHOLDER';
						push( @new_tokens, $as_text );
						last;

					# Otherwise, bail
					} else {
						push( @new_tokens, ( $token, @token_text, $this ) );
						last;
					}
				}

			} else {
				push( @new_tokens, $token );
			}
		}

		return @new_tokens;
	},

	# PyMark - space and Pymark only, then kill any extra space
	PYMARK => sub {
		my @tokens = _only(qw/SPACE PYMARK/)->( @_ );
		if ( $tokens[0]->[0] eq 'PYMARK' ) {
			return $tokens[0];
		} else {
			return @tokens[0,1];
		}
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

	STEP_CLEAN => _convert_to('TEXT', qw/COMMENT PLACEHOLDER QUOTE/),

	TABLE => sub {
		# Remove spaces before and after each PIPE
		my @old_tokens = @_;
		my @new_tokens;

		while ( my $token = shift @old_tokens ) {
			if ( $token->[0] eq 'PIPE' ) {
				# Remove preceeding if it's there
				pop( @new_tokens )
					if ($new_tokens[-1] && $new_tokens[-1]->[0] eq 'SPACE');

				# Remove next space if it's there
				shift( @old_tokens )
					if $old_tokens[0] && $old_tokens[0]->[0] eq 'SPACE';

				# If the previous token was a PIPE too, make our life a little
				# easier by adding a blank text item...
				push( @new_tokens, [TEXT => ''] )
					if $new_tokens[-1] && $new_tokens[-1]->[0] eq 'PIPE';

			}
			push( @new_tokens, $token );
		}

		@new_tokens = _convert_to('TEXT', qw/PIPE COMMENT/)->(@new_tokens);
		@new_tokens = filter('COMBINE_TEXT')->(@new_tokens);

		my @values =
			map { [ CELL => $_->[1] ] }
			grep { $_->[0] eq 'TEXT' }
			@new_tokens;

		my ($comment) = grep { $_->[0] eq 'COMMENT' } @new_tokens;
		return (@values, $comment);

	},

	TO_COMMENT => _convert_to('COMMENT'),
	TO_TEXT    => _convert_to('TEXT'),
	TO_TEXT_AND_COMMENTS => _convert_to('TEXT', 'COMMENT'),

	# Tags...
	TO_TAGS => _convert_to('TEXT', qw/COMMENT TAG SPACE/),
);

my $text_and_comments = filter(qw/TO_TEXT_AND_COMMENTS COMBINE_TEXT/);

our %TYPES = (
	Background => filter(qw/REMOVE_SPACES COMMENTS_ONLY/),
	Comment    => filter(qw/TO_TEXT COMBINE_TEXT TO_COMMENT/),
	COS        => $text_and_comments,
	Example    => filter(qw/REMOVE_SPACES COMMENTS_ONLY/),
	Feature    => $text_and_comments,
	PyMark     => filter(qw/PYMARK/),
	Space      => sub { @_ },
	Step       => filter(qw/PLACEHOLDERS SPACE_TO_TEXT STEP_CLEAN COMBINE_TEXT/),
	Table      => filter(qw/TABLE/),
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

sub filter {compose( map { $RULES{$_} || die $_ } @_)}

sub parse {
	my ($class, $type, $input) = @_;
	local $line_type = $type;

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
