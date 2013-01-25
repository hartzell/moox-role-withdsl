#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package BasicDSL;
    use Moo;
    use MooX::Types::MooseLike::Base qw(ArrayRef CodeRef);

    has x => ( is => 'rw', );
    has y => ( is => 'rw', );
    has z => ( is => 'rw', );

    # required by WithDSL
    sub _build_dsl_keywords {
        my $self = shift;
        return ( [qw( x y ), z => {as => 'omega'}] );
    }

    with qw( MooX::Role::WithDSL );
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

{
    package InvalidDSL;
    # attempts to redefine z as x when x already exists.
    use Moo;
    use MooX::Types::MooseLike::Base qw(ArrayRef CodeRef);

    has x => ( is => 'rw', );
    has y => ( is => 'rw', );
    has z => ( is => 'rw', );

    # required by WithDSL
    sub _build_dsl_keywords {
        my $self = shift;
        return ( [qw( x y ), z => {as => 'x'}] );
    }

    with qw( MooX::Role::WithDSL );

    1;
}

my $invalid_dsl = InvalidDSL->new();

like (exception { my $fails = $invalid_dsl->instance_eval("x(26); x();"); },
      qr/Attempted to redefine method named "x"/,
      'Attempt to use invalid dsl definition dies as expected');

done_testing;
