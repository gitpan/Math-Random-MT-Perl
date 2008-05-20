package Math::Random::MT::Perl;

use strict;
our $VERSION = 1.00;

my $N = 624;
my $M = 397;
my $UP_MASK  = 0x80000000;
my $LOW_MASK = 0x7fffffff;

my $gen = undef;

sub new {
    my ($class, @seeds) = @_;
    my $self = {};
    bless $self, $class;
    $self->mt_init_seed($seeds[0]||time);
    warn "Array of seeds not implemented in this module!\n" if @seeds > 1;
    return $self;
}

sub rand {
    my ($self, $N) = @_;
    if (ref $self) {
        return ($N || 1) * $self->mt_genrand();
    }
    else {
        $N = $self;
        Math::Random::MT::Perl::srand() unless defined $gen;
        return ($N || 1) * $gen->mt_genrand();
    }
}

sub srand { $gen = Math::Random::MT::Perl->new(shift||time) }

sub mt_init_seed {
    my ($self, $seed) = @_;
    my @mt;
    $mt[0] = $seed & 0xffffffff;
    for ( my $i = 1; $i < $N; $i++ ) {
        my $xor = $mt[$i-1]^($mt[$i-1]>>30);
        {   # hack to force required unsigned int overflow rollover
            use integer;
            $mt[$i] = sprintf "%u", 1812433253 * $xor + $i;
        }
    }
    $self->{mt} = \@mt;
    $self->{mti} = $N;
}

sub mt_genrand {
    my ($self,$range) = @_;
    $range ||= 1;
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
    return $range*$y*(1.0/4294967296.0);
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

 # now srand and rand behave as usual.

=head1 DESCRIPTION

Pure Perl implementation of the Mersenne Twister algorithm as implemented in
Math::Random::MT. The Mersenne Twister is a pseudorandom number generator
developed by Makoto Matsumoto and Takuji Nishimura.

This module implements two interfaces, as described in the synopsis
above. It defines the following functions.

=head2 Functions

=over

=item new($seed)

Creates a new generator seeded with an unsigned 32-bit integer.

=item rand($num)

Can be called via the OO in interface or exported. Behaves exactly like
Perl's builtin rand(), returning a number uniformly distributed in [0, $num)
($num defaults to 1) except the underlying complexity is 32 bits rather than
some small fraction of this.

=item srand($seed)

Behaves just like Perl's builtin srand(). If you use this interface, it
is strongly recommended that you call I<srand()> explicitly, rather than
relying on I<rand()> to call it the first time it is used. Has no effect if
called via OO interface - pass the seed to new.

=back

=head2 EXPORT

None by default. rand() and srand() on demand.

=head1 SEE ALSO

Math::Random::MT

<URL:http://www.math.keio.ac.jp/~matumoto/emt.html>

=head1 AUTHOR

Dr James Freeman E<lt>airmedical@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Dr James Freeman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
