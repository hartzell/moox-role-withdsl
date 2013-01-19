#!perl

use strict;
use warnings;

use Test::More;

{ package Play;
  use Moo;
  with qw( MooX::Role::WithDSL );

  has value => (is => 'rw');
  1;
}

my $p1 = Play->new();
my $p2 = Play->new();

$p1->instance_eval(10);
$p2->instance_eval(100);

is ($p1->value, 10, 'Got the right value for p1');
is ($p2->value, 100, 'Got the right value for p2');

done_testing;
