What?
-----

An aggregation of the Cucumber feature files from various projects, intended to
allow tracking of changes to the parsing capabilities to the Perl module
Test::BDD::Cucumber.

Licenses
--------

The different feature files have different licenses, Test::BDD::Cucumber a
different license still. There is no intention to distribute the various pieces
of code and data here beyond the existence of this GitHub repository. I have
tried to get this right, and so:

Everything in `code/` should be considered to be licensed in the same way that 
Test::BDD::Cucumber is - that is, under the same terms as Perl 5.

Everything else is in subdirectories under `corpora`. Each subdirectory has:

`README` - where the corpus came from, how it was licensed, and what's been
changed

`LICENSE` - the original license it was distributed with

`src` - the original files from the corpus

`derived` - derived files from the corpus - generally dumps of 
Test:BDD::Cucumber objects - these are licensed as per the license of the
original files


