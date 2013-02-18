#!perl

use strict;
use warnings;

use lib qw(t/lib);

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('BasicDSL');
    use_ok('InvalidDSL');
}

my $dsl = BasicDSL->new();
can_ok( $dsl, qw(x y) );

my $new_value = $dsl->instance_eval("x(10); x();");
is( $new_value, 10, "It worked!" );
is( $dsl->x,    10, "Really!" );

my $other_dsl   = BasicDSL->new();
my $other_value = $other_dsl->instance_eval("x();");
is( $other_dsl->x, undef, "And another one" );
$other_value = $other_dsl->instance_eval("x(42);");
is( $other_dsl->x, 42, "And another one" );

is( $dsl->x, 10, "And it STILL works!" );

##
## check out renaming
##
my $renaming = $dsl->instance_eval("omega(26); omega();");
is ($renaming, 26, 'renaming x to omega worked');

like (exception { my $fails = $dsl->instance_eval("z(26); z();"); },
      qr/Undefined subroutine &MooX::Role::WithDSL::ANON_\d+::z/,
      'Attempt to use z dies as expected');

## make sure invalid renaming throws a fit.
my $invalid_dsl = InvalidDSL->new();

like (exception { my $fails = $invalid_dsl->instance_eval("x(26); x();"); },
      qr/Attempted to redefine method named "x"/,
      'Attempt to use invalid dsl definition dies as expected');

done_testing;
