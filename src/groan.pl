#!/usr/bin/perl
#
# File:     Groan.pl
# Author:   Angus McIntyre
# Date:     18.09.1994
# Updated:  14.07.1998
#
# Hacky Perl implementation of a Groan program, a program to generate
# random text from simple RTN grammars. The original 'Groan' was written
# in Fortran by Chris Boyd. This was implemented, independently, using
# Perl.
#
# The grammar format used by 'Groan' is as follows:
#
#   rule --> term '-->' expansion [expansion]* ';'
#   term --> symbol
#   expansion --> term | string
#
# A symbol may consist of any alphanumeric characters; a string may
# consist of any characters (except double-quotes), enclosed in
# double-quotes. Newlines may be included in strings as '\n', and
# will be expanded to '<BR>' by the Groan program.
#
# Example:
#
#   s --> np vp;
#   np --> det n;
#   det --> "the";
#   det --> "a";
#   n --> "cat";
#   vp --> v;
#   v --> "walks";
#
# is a valid Groan grammar that would generate a small and very dull
# fragment of English.
#
# ---------------------------------------------------------------------------
# LEGAL NOTICE: This script may be freely copied, distributed and modified.
# Use of the script is at the risk of the user. The script is presented
# "as-is" without any warranty, and the author is not liable for any loss
# or damages arising out of the use of or failure to use this script. This
# notice must appear in any modified copy of the script in which the name
# of the original author also appears.
# ---------------------------------------------------------------------------

# Set to flush output directly

$|=1;

# ---------------------------------------------------------------------------
#                               GLOBALS
# ---------------------------------------------------------------------------

$topsymbol = "";

# ---------------------------------------------------------------------------
#                               MAIN ROUTINE
# ---------------------------------------------------------------------------

# Get the path to the script, seed the random number generator, and call
# the main routine.

$path = $ARGV[0];

srand(time|$$);

eval("main()");

# If an error occurs, report it

if ($@) {
	print <<"EndOfTEXT";
An error occurred:
Error: $@
File: $path
EndOfTEXT
}

# main
#
# main routine

sub main {

# Read the grammer and generate some text based on the top
# symbol of the grammar.

readgrammar($path);
generate($topsymbol);

}


# ---------------------------------------------------------------------------
#                                   SUBROUTINES
# ---------------------------------------------------------------------------

# readgrammar
#
# Read a grammar file from disk.

sub readgrammar {

    local($grammarfile) = pop(@_);

    # Open the file

    open(GRAMMAR,$grammarfile) ||
    	die "can't open grammar '$grammarfile': $!";

    # Set the record separator to ';'

    local($/) = ";";

    while(<GRAMMAR>) {

        # Eliminate leading whitespace and split the input

        s/^\s*//;
        ($lhs,$arrow,$rhs) = split(/\s/,$_,3);

        # If no top symbol is defined for the grammar, take the
        # first one that comes along

        if (!$topsymbol) { $topsymbol = $lhs; }

        # Extract the right-hand side elements. First, chop
        # the trailing semi-colon off, then add a space in its
        # place and last, with a very complex pattern, split
        # the items into a list made up of tokens and strings.

        $_ = $rhs;
        chop;
        $_ .= " ";
        @rhs = /(\w+)\s+|("[^"]+")\s+/g;

        # Store the extracted information as a colon-separated
        # string inside a tab-separated string. Whew!

        $grammar{$lhs} .= join(";",@rhs) . "\t";
    }

    # Restore the input terminator

    local($/) = "\n";
}

# generate
#
# Generate from a given symbol

sub generate {
    local($symbol) = pop(@_);

    # Find out what ways the symbol can be expanded

    $options = $grammar{$symbol};
    if ($options) {
        chop($options);
        @choices = split(/\t/,$options);

        # Find out how many expansions there are, and choose
        # one at random.

        $choicenumber = int(rand(scalar(@choices)));
        $choice = $choices[$choicenumber];

        # Split up the expansion to get at the individual
        # tokens and strings that make it up, then loop
        # through those

        foreach $expansion (split(/;/,$choice)) {

            # If the item is a string - flanked by quotes - then
            # output it, turning newlines into HTML <BR> constructs

            if ($expansion =~ /"([^"]+)"/) {
                $literal = $1;
                # bmt $literal =~ s/\\n/<BR>\n/g;
                $literal =~ s/\\n/\n/g;
                $literal =~ s/\\t/\t/g;
                print $literal;
            }

            # Otherwise, recursively generate the symbol

            else { &generate($expansion); }
        }
    }
}

