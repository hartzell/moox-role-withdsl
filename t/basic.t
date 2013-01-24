#!perl

use strict;
use warnings;

use Test::More;

{ package BasicDSL;
  use Moo;
  use MooX::Types::MooseLike::Base qw(ArrayRef CodeRef);


  has x => (is => 'rw',);
  has y => (is => 'rw',);

  # required by WithDSL
  sub _build_dsl_keywords {
    my $self = shift;
    return( [qw( x y )] );
  }

  with qw( MooX::Role::WithDSL );

  1;
}

my $dsl = BasicDSL->new();
can_ok($dsl, qw(x y));

my $new_value = $dsl->instance_eval("x(10); x();");
is($new_value, 10, "It worked!");
is($dsl->x, 10, "Really!");

my $other_dsl = BasicDSL->new();
my $other_value = $other_dsl->instance_eval("x();");
is($other_dsl->x, undef, "And another one");
$other_value = $other_dsl->instance_eval("x(42);");
is($other_dsl->x, 42, "And another one");

is($dsl->x, 10, "And it STILL works!");

done_testing;
