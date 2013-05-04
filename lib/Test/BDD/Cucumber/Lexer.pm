package Test::BDD::Cucumber::Lexer;

use strict;
use warnings;
use Moose;
use Test::BDD::Cucumber::Util;

=head1 ATTRIBUTES

=head2 source

String, required. The source - probably filename - that the input came from.

=cut

has 'source' => ( isa => 'Str', is => 'ro', required => 1 );
has 'input'  => ( isa => 'Str', is => 'rw', required => 1 );
has 'input_original' => ( isa => 'Str', is => 'rw' );

has 'mode'   => ( isa => 'Str', is => 'rw', default => 'general' );

has 'cursor_line'     => ( isa => 'Int', is => 'rw', default => 1 );
has 'cursor_row'      => ( isa => 'Int', is => 'rw', default => 1 );
has 'cursor_absolute' => ( isa => 'Int', is => 'rw', default => 0 );

# Performance? Lexing Gherkin? Possible, but I'm interested in being able to
# remember how all of this works in a few months when someone comes up with a
# weird bug I hadn't considered. Therefore, this is slow, but presumably pretty
# easily to grok what's going on.
sub tokens {
    my $self = shift;
    $self->_encode_input;

    my @tokens;

    while (my $token = $self->next_token) {
        push( @tokens, $token );
        last if $token->{'type'} eq 'EOF';
    }

    return @tokens;
}

sub _encode_input {
    my $self = shift;
     $self->input_original( $self->input );

    # Escape double backslashes. This makes using regular expressions for
    # parsing dramatically easier, because we can use simple lookaheads
    $self->input( Test::BDD::Cucumber::Util::encode_double_backslash(
        $self->input ) );

    return $self;
}

sub next_token {
    my $self = shift;

    # MAKE SURE YOU'VE CALLED _encode_input EXACTLY ONCE BEFORE THIS IS RUN.

    # We are in a given mode. The mode has a series of next possible steps.
    for my $step ( $self->mode_steps() ) {

        # The match step does updating of state
        if ( my $token = $self->match( $step ) ) {
            return $token;
        }
    }

    # If we got here, there were no matches
    return $self->throw_no_match;
}

my $EOL = qr/^(\r?\n)/;

our %steps;
$steps{'TAG'}        = { match => qr/^(\@[^\@\s]+)/, post_mode => 'tagline' };
$steps{'WHITESPACE'} = { match => qr/^([ \t]+)/, discard => 1 };
$steps{'EOL'}        = { match => $EOL, post_mode => 'general', discard => 1 };
$steps{'ESCAPED'}    = { match => qr/^(\\.)/ };
$steps{'COS'}        = { match => qr/^(.+)/, post_mode => 'cos' };
$steps{'COMMENT'}    = { match => qr/^#(.+)/, discard => 1 };

$steps{'QUOTE'}      = { match => qr/^"/  };

$steps{'INTERPOLATION_START'}   = { match => qr/^\</  };
$steps{'INTERPOLATION_CONTENT'} = { match => qr/^(.)/ };
$steps{'INTERPOLATION_END'  }   = { match => qr/^>/   };

%steps = ( %steps,

    FEATURE    => { match => qr/^(feature:)/i,    post_mode => 'feature_description'    },
    BACKGROUND => { match => qr/^(background:)/i, post_mode => 'background_description' },
    SCENARIO   => { match => qr/^(scenario:)/i,   post_mode => 'scenario_description'   },

    DESCRIPTION => { match => qr/^([^\\#\r\n]+)/ },

    FEATURE_DESCRIPTION_EOL  => { match => $EOL, discard => 1, post_mode => 'cos'   },
    SCENARIO_DESCRIPTION_EOL => { match => $EOL, discard => 1, post_mode => 'steps' },
    COS_EOL                  => { match => $EOL, discard => 1, post_mode => 'cos'   },
    STEP_EOL                 => { match => $EOL, discard => 1, post_mode => 'steps' },

    GIVEN => { match => qr/^(given)(?: )/i, post_mode => 'step' },
    WHEN  => { match => qr/^(when)(?: )/i,  post_mode => 'step' },
    THEN  => { match => qr/^(then)(?: )/i,  post_mode => 'step' },
    AND   => { match => qr/^(and)(?: )/i,   post_mode => 'step' },
    BUT   => { match => qr/^(but)(?: )/i,   post_mode => 'step' },
    STAR  => { match => qr/^(\*)(?: )/,     post_mode => 'step' },

    PYSTRING => {
        match => qr/^([ \t]*""".+?\n[ \t]*"""[ \t]*\n)/s,
        post_mode => 'steps',
    },

);

# In general, COMMENT WHITESPACE and EOL are reasonable
my @CWE = (qw/EOL COMMENT WHITESPACE/);
my @GENERAL = (@CWE, (qw/TAG FEATURE BACKGROUND SCENARIO/));

our %steps_by_modes = (
    # General is mostly anything that isn't steps...
    general => [@GENERAL],

    # Immediately after a feature, we have Conditions of Satisfaction, although
    # we'll happily take anything that isn't, and drop in to that instead. This
    # is like plaintext, only we'll accept 'COS' as well. Note this places
    # COS_EOL ahead of the general one, so it'll match first.
    cos => ['COS_EOL', @GENERAL, 'COS' ],

    feature_description    => ['FEATURE_DESCRIPTION_EOL', @CWE, 'DESCRIPTION'],
    # No description allowed for backgrounds, but the ->steps EOL is important
    background_description => ['SCENARIO_DESCRIPTION_EOL', @CWE ],
    scenario_description   => ['SCENARIO_DESCRIPTION_EOL', @CWE, 'DESCRIPTION'],

    # A list of steps. An EOL here means the end of the steps
    steps => [qw/PYSTRING GIVEN WHEN THEN AND BUT STAR/, @CWE],
    # An actual step
    step => ['STEP_EOL', @CWE, 'DESCRIPTION'],

    # Other tags, perhaps
    tagline => [@CWE, qw/TAG/],
);

sub mode_steps {
    my $self = shift;
    my $tags = $steps_by_modes{ $self->mode() };

    return map {
        my $type = $_;
        my $hash = $steps{ $type };
        { type => $type, %$hash };
    } @$tags;

}

sub match {
    my ( $self, $step ) = @_;
    my $buffer = $self->input;

    # EOF
    return {
        text => "",
        type => "EOF",
        position => {
            cursor => $self->cursor_absolute,
            line => $self->cursor_line,
            row => $self->cursor_row,
        },
    } unless length $buffer;

    if ( $buffer =~ $step->{'match'} ) {
        # Put together the token
        my $match = {
            text => Test::BDD::Cucumber::Util::decode_double_backslash($1),
            type => $step->{'type'},
            discard => $step->{'discard'},
            position => {
                cursor => $self->cursor_absolute,
                line => $self->cursor_line,
                row => $self->cursor_row,
            },
        };
        # Advance the cursor
        $self->advance_cursor( $match );
        # Update the mode
        $self->mode( $step->{'post_mode'} ) if $step->{'post_mode'};
        # Return the match
        return $match;
    } else {
        return;
    }
}

sub advance_cursor {
    my ( $self, $match ) = @_;
    my $l = length( $match->{'text'} );

    # Update the absolute cursor
    $self->cursor_absolute( $self->cursor_absolute + $l );

    # Update the lines/rows
    # The --'s mean the split doesn't hide undefs, and also we don't need to do
    # a +1 in cursor_row in the first instance
    my @lines = split(/\r?\n/, '-' . $match->{'text'} . '-');
    if ( @lines > 1 ) {
        $self->cursor_line( $self->cursor_line + $#lines );
        $self->cursor_row( length( pop @lines ) );
    } else {
        $self->cursor_row( $self->cursor_row + $l );
    }

    # Remove some of the input buffer. We need the length as if it was encoded
    # for this to work...
    my $buffer = substr( $self->input, $l );
    $self->input( $buffer );
}

sub throw_no_match {
    my $self = shift;
    die sprintf(
        "Unexpected input while in parse-mode %s, at line %d, row %d: [%s]",
        $self->mode(),
        $self->cursor_line,
        $self->cursor_row,
        substr( $self->input(), 0, 20 ),
    );
}

1;