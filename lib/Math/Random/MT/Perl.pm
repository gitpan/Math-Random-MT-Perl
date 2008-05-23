package Math::Random::MT::Perl;

use strict;
#use warnings;
our $VERSION = 1.03;

my $N = 624;
my $M = 397;
my $UP_MASK  = 0x80000000;
my $LOW_MASK = 0x7fffffff;

my $gen = undef;

sub new {
    my ($class, @seeds) = @_;
    my $self = {};
    bless $self, $class;
    @seeds > 1 ? $self->mt_setup_array(@seeds) :
                 $self->mt_init_seed($seeds[0]||time);
    return $self;
}

sub rand {
    my ($self, $range) = @_;
    if (ref $self) {
        return ($range || 1) * $self->mt_genrand();
    }
    else {
        $range = $self;
        Math::Random::MT::Perl::srand() unless defined $gen;
        return ($range || 1) * $gen->mt_genrand();
    }
}

sub srand { $gen = Math::Random::MT::Perl->new(shift||time) }

# Note that we need to use integer some of the time to force integer overflow
# rollover ie 2**32+1 => 0. Unfortunately we really want uint but integer
# casts to signed ints, thus we can't do everything within an integer block,
# specifically the bitshift xor functions below. The & 0xffffffff is required
# to constrain the integer to 32 bits on 64 bit systems.
sub mt_init_seed {
    my ($self, $seed) = @_;
    my @mt;
    $mt[0] = $seed & 0xffffffff;
    for ( my $i = 1; $i < $N; $i++ ) {
        my $xor = $mt[$i-1]^($mt[$i-1]>>30);
        { use integer;  $mt[$i] = (1812433253 * $xor + $i) & 0xffffffff }
    }
    $self->{mt} = \@mt;
    $self->{mti} = $N;
}

sub mt_setup_array {
    my ($self, @seeds) = @_;
    @seeds = map{ $_ & 0xffffffff }@seeds;  # limit seeds to 32 bits
    $self->mt_init_seed( 19650218 );
    my @mt = @{$self->{mt}};
    my $i = 1;
    my $j = 0;
    my $n = @seeds;
    my $k = $N > $n ? $N : $n;
    my ($uint32, $xor);
    for (; $k; $k--) {
        $xor = $mt[$i-1] ^ ($mt[$i-1] >> 30);
        { use integer; $uint32 = ($xor * 1664525) & 0xffffffff }
        $mt[$i] = ($mt[$i] ^ $uint32);
        { use integer; $mt[$i] = ($mt[$i] + $seeds[$j] + $j) & 0xffffffff }
        $i++; $j++;
        if ($i>=$N) { $mt[0] = $mt[$N-1]; $i=1; }
        if ($j>=$n) { $j=0; }
    }
    for ($k=$N-1; $k; $k--) {
        $xor = $mt[$i-1] ^ ($mt[$i-1] >> 30);
        { use integer; $uint32 = ($xor * 1566083941) & 0xffffffff }
        $mt[$i] = ($mt[$i] ^ $uint32) - $i;
        $i++;
        if ($i>=$N) { $mt[0] = $mt[$N-1]; $i=1; }
    }
    $mt[0] = 0x80000000;
    $self->{mt} = \@mt;
}

sub mt_genrand {
    my ($self) = @_;
    my ($kk, $y);
    my @mag01 = (0x0, 0x9908b0df);
    if ($self->{mti} >= $N) {
        for ($kk = 0; $kk < $N-$M; $kk++) {
            $y = ($self->{mt}->[$kk] & $UP_MASK) | ($self->{mt}->[$kk+1] & $LOW_MASK);
            $self->{mt}->[$kk] = $self->{mt}->[$kk+$M] ^ ($y >> 1) ^ $mag01[$y & 1];
        }
        for (; $kk < $N-1; $kk++) {
            $y = ($self->{mt}->[$kk] & $UP_MASK) | ($self->{mt}->[$kk+1] & $LOW_MASK);
            $self->{mt}->[$kk] = $self->{mt}->[$kk+($M-$N)] ^ ($y >> 1) ^ $mag01[$y & 1];
        }
        $y = ($self->{mt}->[$N-1] & $UP_MASK) | ($self->{mt}->[0] & $LOW_MASK);
        $self->{mt}->[$N-1] = $self->{mt}->[$M-1] ^ ($y >> 1) ^ $mag01[$y & 1];
        $self->{mti} = 0;
    }
    $y  = $self->{mt}->[$self->{mti}++];
    $y ^= $y >> 11;
    $y ^= ($y <<  7) & 0x9d2c5680;
    $y ^= ($y << 15) & 0xefc60000;
    $y ^= $y >> 18;
    return $y*(1.0/4294967296.0);
}

sub import {
    no strict 'refs';
    my $pkg = caller;
    for my $sym (@_) {
       *{"${pkg}::$sym"} = \&$sym  if $sym eq "srand" or $sym eq "rand";
    }
}

1;

__END__

=head1 NAME

Math::Random::MT::Perl - Pure Perl Pseudorandom Number Generator

=head1 SYNOPSIS

 use Math::Random::MT::Perl;

 $gen = Math::Random::MT::Perl->new($seed);
 print $gen->rand(3);

 OR

 use Math::Random::MT qw(srand rand);

 # now srand and rand behave as usual, except with 32 bit precsision not ~15

=head1 DESCRIPTION

Pure Perl implementation of the Mersenne Twister algorithm as implemented in
C/XS in Math::Random::MT. The output is identical to the C/XS version. The
Mersenne Twister is a 32 bit pseudorandom number generator developed by
Makoto Matsumoto and Takuji Nishimura. The algorithm is characterised by
a very uniform distribution but is not cryptographically secure. What this
means in real terms is that it is fine for modelling but no good for crypto.

This module implements the same two interfaces found in Math::Random::MT,
as described in the synopsis above. It defines the following functions.

=head2 Functions

=over

=item new($seed)

Creates a new generator seeded with an unsigned 32-bit integer.

=item new(@seed)

Creates a new generator seeded with an array of unsigned 32-bit integers.

=item rand($num)

Can be called via the OO in interface or exported. Behaves exactly like
Perl's builtin rand(), returning a number uniformly distributed in [0, $num)
($num defaults to 1) except the underlying complexity is 32 bits rather than
some small fraction of this.

=item srand($seed)

Behaves just like Perl's builtin srand(). If you use this interface, it
is strongly recommended that you call I<srand()> explicitly, rather than
relying on I<rand()> to call it the first time it is used. Has no effect if
called via OO interface - pass the seed(s) to new.

=back

=head2 Export

Nothing by default. rand() and srand() on demand.

=head1 SPEED

Runs around 1/3-1/2 as fast as Math::Random::MT, however that still means a
Benchmark random number generation speed of 100,000/sec on modest hardware,
so this is unlikely to cause a significant bottleneck in most circumstances.

=head1 SEE ALSO

Math::Random::MT

http://www.math.keio.ac.jp/~matumoto/emt.html

=head1 AUTHOR

Dr James Freeman E<lt>airmedical@gmail.comE<gt>

=head2 Credits

almut from perlmonks for 64 bit debug and fix.

Abhijit Menon-Sen, Philip Newton and Sean M. Burke who contributed to
Math::Random::MT as this module is simply a translation.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Dr James Freeman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
