use strict;
use warnings;
use Test::More;
use Benchmark qw(timediff timestr);
BEGIN {
   use_ok('Math::Random::MT::Perl', qw(srand));
}


# Make sure that automatic seeds generated close in time are different.

my ($autoseed1, $autoseed2, $autoseed3, $autoseed4);

# Generate a series of 3 random numbers using an autogenerated seed
ok $autoseed1 = srand();
ok $autoseed2 = srand();
ok $autoseed3 = srand();
ok $autoseed4 = srand();
cmp_ok $autoseed1, '!=', $autoseed2;
cmp_ok $autoseed2, '!=', $autoseed3;
cmp_ok $autoseed3, '!=', $autoseed4;

done_testing();
