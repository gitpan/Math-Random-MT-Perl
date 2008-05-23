use strict;

use Test;
use vars qw($loaded);
use Benchmark qw(timediff timestr);

BEGIN { plan tests => 4 }
END   { print "not ok 1\n" unless $loaded }

use Math::Random::MT::Perl;
ok($loaded = 1);
ok(my $gen = Math::Random::MT::Perl->new(5489));
ok((sprintf"%.12f",$gen->rand()), 0.814723691903);
ok((sprintf"%.12f",$gen->rand()), 0.135477004107);
