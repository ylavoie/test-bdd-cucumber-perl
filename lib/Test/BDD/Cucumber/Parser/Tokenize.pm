package Test::BDD::Cucumber::Parser::Tokenize;

use strict;
use warnings;

use Test::BDD::Cucumber::Model::Token;

=head1 NAME

Test::BDD::Cucumber::Parser::Tokenize - Tokenize lines of Gherkin

=head1 DESCRIPTION

Given a line of text, and a type, tokenizes it

=head1 SYNOPSIS

 my @tokens = Test::BDD::Cucumber::Parser::Tokenize->parse({
 	line_type => '',
 	content   => '',
 });

=head1 WARNING

No user-serviceable parts in here. Opening voids warranty.

=cut

# How this all works...
#
# We do three passes over each incoming line. The first of them blindly picks up
# all possible tokens, trying to match in order tokens from @TOKENS. The second
# tries to make sense of those, given what it knows about the line type. The
# final pass does little bits of cleanup on the final token set. Here's a worked
# example:
#
# Input: Feature: I "am" <here> #ok
#
# First pass gives back:
#   KEYWORD[Feature: ]
#   TEXT[I]
#   SPACE[ ]
#   QUOTE["]
#   TEXT[AM]
#   QUOTE["]
#   SPACE[ ]
#   PLACE_OPEN[<]
#   TEXT[here]
#   PLACE_CLOSE[>]
#   COMMENT[ #ok]
#
# Now, what we know about features is that they don't have quotes, they don't
# have place holders, and that there's no real difference between spaces and
# text in them. So we turn everything that's not a KEYWORD, TEXT, or COMMENT in
# to text, and join it all together:
#
# Second pass gives back:
#   KEYWORD[Feature: ]
#   TEXT[I "am" <here>]
#   COMMENT[ #ok]
#
# Which is almost there. But we've captured some extra spaces and so on in the
# COMMENT and KEYWORD. We're also going to upgrade what we've got to actual
# token objects.
#
# Third pass gives back:
#   TBCM::Token{ type => KEYWORD, text => 'Feature', raw => 'Feature: '}
#   TBCM::Token{ type => TEXT,    text => 'I "am" <here>', raw => 'I "am" <here>'}
#   TBCM::Token{ type => COMMENT, text => 'ok', raw => ' #ok'}
#
# Sorted.
#
# You should only ever mess around with the output of the third type - it's
# highly likely that one day I'll grow an actual clue and implement a proper
# parser, but the output from that will be the objects from the third step.
#

# Diagnostics that we'll override with local as appropriate
our $line_type;

# Tokens. Note that some token types appear more than once! This is because this
# is a list of tokens, rather than a dictionary of them. So don't hang anything
# important off this list.
our @TOKENS = (
	[ TEXT        => qr/^\\(.)/ ], # Escapes
	[ COMMENT     => qr/^(\s*# ?.*)/ ],
	[ PYMARK      => qr/^(""")/ ],
	[ QUOTE       => qr/^(")/   ],
	[ TAG         => qr/^(\@)/  ],
	[ PLACE_OPEN  => qr/^(\<)/  ],
	[ PLACE_CLOSE => qr/^(\>)/  ],
	[ SPACE       => qr/^(\s+)/ ],
	[ COLON       => qr/^(\:)/  ],
	[ PIPE        => qr/^(\|)/  ],
	[ KEYWORD     => qr/^([^\\#"\<\>\s\|]+\:\s*)/ ],
	[ TEXT        => qr/^([^\\#"\<\>\s\:\|]+)/ ],
);

=head1 METHODS

=head2 parse

Accepts a hashref of C<content> and C<line_type>, returns
L<Test::BDD::Cucumber::Model::Token> objects.

=cut

sub parse {
	my $class = shift;
	my $args  = shift;

	local $line_type = $args->{'line_type'};
	my $content = $args->{'content'};

	# First pass, string -> dumb tokens
	my @dumb_tokens = $class->_lex( $content );

	# Second pass, contextual clean of tokens
	my @consolidated = $class->_consolidate( $line_type, @dumb_tokens );

	# Third pass, turn the tokens in to objects
	my @tokens = $class->_clean_and_instantiate( @consolidated );
}

# Simple first-stage lex. Accepts a string, returns a list of tokens in the form
# [ TOKEN => "" ]
sub _lex {
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

# Taking tokens of the form [ TOKEN => "" ], performs any cleanup, and then
# creates a TBCM::Token object from it. The CLEANUP hash has cleanup routines
# for each token type, which should return a list of TYPE, TEXT, RAW
our %CLEANUP = (
	CELL    => sub {
		return('', $_[0]) unless $_[0] =~ m/\S/;
		$_[0] =~ m/^\s*(.+?)\s*$/; return $1, $_[0];
	},
	COMMENT => sub { $_[0] =~ m/^\s*#\s*(.+?)\s*$/; return $1, $_[0]; },
	KEYWORD => sub { $_[0] =~ m/^\s*(\w+)\:?\s*/;   return $1, $_[0]; },
	PLACEHOLDER => sub { $_[0] =~ m/^\<(.+)\>$/;    return $1, $_[0]; },
	TAG     => sub { $_[0] =~ m/^\@(.+)/;           return $1, $_[0]; },
);
sub _clean_and_instantiate {
	my $class = shift;
	map {
		# Incoming token
		my ( $type, $in_text ) = @$_;
		# Outgoing token
		my $token = { type => $type };

		# Cleanup routine
		my $cleanup = $CLEANUP{$type} || sub { $_[0], $_[0] };

		my ( $text, $raw ) = $cleanup->( $in_text );
		$token->{'text'} = $text;
		$token->{'raw'}  = $raw;

		Test::BDD::Cucumber::Model::Token->new( %$token );

	} @_;
}

# This is the complicated one... Essentially we define a series of filters for
# each line type.
our %LINE_TYPES = (
	Background => [qw/
		TRIM_LEADING_SPACE
		EXACT_MATCH:KEYWORD_COMMENT?
	/],
	Comment => [qw/
		TO_TEXT_EXCEPT:TEXT
		COMBINE_TEXT
		TO_COMMENT
	/],
	COS => [qw/
		TRIM_LEADING_SPACE
		TO_TEXT_EXCEPT:COMMENT
		COMBINE_TEXT
	/],
	Examples => [qw/
		TRIM_LEADING_SPACE
		EXACT_MATCH:KEYWORD_COMMENT?
	/],
	Feature => [qw/
		TRIM_LEADING_SPACE
		TO_TEXT_EXCEPT:KEYWORD_COMMENT
		COMBINE_TEXT
	/],
	PyMark => [qw/
		TRIM_TRAILING_SPACE
		EXACT_MATCH:SPACE?_PYMARK
	/],
	Scenario => [qw/
		TRIM_LEADING_SPACE
		TO_TEXT_EXCEPT:KEYWORD_COMMENT
		COMBINE_TEXT
	/],
	Step => [qw/
		TRIM_LEADING_SPACE
		EXTRACT_STEP_KEYWORD
		PLACEHOLDERS
		TO_TEXT_EXCEPT:COMMENT_PLACEHOLDER_QUOTE_KEYWORD
		COMBINE_TEXT
	/],
	Space => [qw/ID/],
	Table => [qw/
		TRIM_LEADING_SPACE
		TO_TEXT_EXCEPT:COMMENT_TEXT_PIPE
		COMBINE_TEXT
		MAKE_CELLS
	/],
	Tag => [qw/
		TRIM_LEADING_SPACE
		TO_TEXT_EXCEPT:COMMENT_TAG_SPACE
		COMBINE_TEXT
		MAKE_TAGS
	/],
	Quoted => [qw/QUOTED/],

);

our %FILTERS = (
	_REVEAL => sub {
		require Data::Dumper;
		die Data::Dumper::Dumper(\@_);
	},

	# Combines adjacent TEXT tokens
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

	# Tokens must match...
	'EXACT_MATCH:' => sub {
		my ( $match_spec, @tokens ) = @_;
		my @ok;

		for my $spec (@$match_spec) {
			# Optional tokens ending in a ?
			if ( $spec =~ s/\?$// ) {
				next unless @tokens && $tokens[0]->[0] eq $spec;
			}

			# Out of tokens?
			unless ( @tokens ) {
				_parse_error({
					context => \@ok,
					error   => "Missing required token of type [$spec]",
				});
			}

			# Wrong token type?
			unless ( $tokens[0]->[0] eq $spec ) {
				_parse_error({
					context => \@ok,
					error   => sprintf( "Illegal token [%s|%s]",
						@{$tokens[0]}
					)
				});
			}

			# OK, keep going
			push( @ok, shift( @tokens ) );
		}

		return @ok;
	},

	EXTRACT_STEP_KEYWORD => sub {
		my ( $text, $space, @tokens) = @_;
		return [ KEYWORD => $text->[1] . $space->[1] ], @tokens;
	},

	ID => sub { @_ },

	MAKE_CELLS => sub {
		my @tokens = @_;

		# Remove and save the last comment
		my ($comment) = pop( @tokens );
		unless ($comment->[0] eq 'COMMENT') {
			push( @tokens, $comment );
			undef $comment;
		}

		# Last token is a PIPE, right?
		_parse_error({
			context => \@tokens,
			error => "Trailing content after table cells",
		}) unless $tokens[-1]->[0] eq 'PIPE';
		pop( @tokens );

		# Make sure every PIPE is followed by a non-PIPE
		my @cells;
		while ( @tokens ) {
			my $pipe = shift( @tokens );
			my $next = $tokens[0];
			# If it's an empty cell, put in a placeholder
			if ( (! $next) || $next->[0] eq 'PIPE' ) {
				push( @cells, [ CELL => '' ] );
			# Otherwise, stick in the next token
			} else {
				push( @cells, [ CELL => shift( @tokens )->[1] ] );
			}
		}

		return @cells, $comment ? $comment : ();
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

			push( @tags, [ TAG => '@' . $text->[1] ] );
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
						my $as_text = join '', map { $_->[1] } @token_text;
						push( @new_tokens, [PLACEHOLDER => '<'.$as_text.'>'] );
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

	QUOTED => sub {
		my ($first, @tokens) = @_;
		my $token = [ TEXT => join '', map { $_->[1] } @tokens];
		if ( $first->[0] eq 'SPACE' ) {
			return $first, $token;
		} else {
			$token->[1] = $first->[1] . $token->[1];
			return $token;
		}
	},

	TO_COMMENT => _convert_to('COMMENT'),

	# Turns all except the provided types in to TEXT tokens
	'TO_TEXT_EXCEPT:' => sub {
		my ( $except, @tokens ) = @_;
		_convert_to( TEXT => @$except )->( @tokens );
	},

	# Removes leading spaces
	TRIM_LEADING_SPACE => sub {
		my @tokens = @_;
		shift( @tokens ) while ( $tokens[0]->[0] && $tokens[0]->[0] eq 'SPACE');
		return @tokens;
	},

	TRIM_TRAILING_SPACE => sub {
		my @tokens = @_;
		pop( @tokens ) while ( $tokens[-1]->[0] && $tokens[-1]->[0] eq 'SPACE');
		return @tokens;
	}
);

sub _consolidate {
	my ( $class, $type, @tokens ) = @_;
	my @filters = @{ $LINE_TYPES{ $type } ||
		die "Don't know how to handle line type $type" };

	# Keep iterating over tokens, applying filters
	for my $filter_name ( @filters ) {
		# Can we look up the filter?
		if ( my $filter = $FILTERS{$filter_name} ) {
			@tokens = $filter->( @tokens );

		# Is it a special case?
		} elsif ( $filter_name =~ m/(\w+:)([\w\?]+)/ ) {
			my $filter = $FILTERS{ $1 } ||
				die "Can't find a filter called [$1]";
			@tokens = $filter->( [split(/_/, $2)], @tokens );

		# No joy :-(
		} else {
			die "Can't find a filter called [$filter_name]"
		}
	}

	return @tokens;
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

sub _parse_error {
	use Data::Dumper;
	warn "PARSE ERROR";
	die Dumper \@_;
}

1;