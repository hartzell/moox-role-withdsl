#!perl

use strict;
use warnings;

use Test::More;

{ package BasicDSL;
  use Moo;
  with qw( MooX::Role::WithDSL );

  has x => (is => 'rw',);
  has y => (is => 'rw',);
  has dsl_keywords => (
                    builder => "_build_dsl_keywords",
                    is => "ro",
                    isa => "ArrayRef",
                    lazy => 1,
                   );

  sub _build_dsl_keywords {
    my $self = shift;
    return( [qw( x y )] );
  }

  1;
}

my $dsl = BasicDSL->new();

can_ok($dsl, qw(x y));

done_testing;
