package InvalidDSL;

# attempts to rename z to x when x already exists.
use Moo;

has x => ( is => 'rw', );
has y => ( is => 'rw', );
has z => ( is => 'rw', );

# required by WithDSL
sub _build_dsl_keywords {
    my $self = shift;
    return ( [ qw( x y ), z => { as => 'x' } ] );
}

with qw( MooX::Role::WithDSL );

1;

