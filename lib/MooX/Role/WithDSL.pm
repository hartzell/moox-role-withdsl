package MooX::Role::WithDSL;

# ABSTRACT: Add DSL features to your class.

=head1 SYNOPSIS

    use Test::More;
    use Test::Deep;

    # put together class with a simple dsl
    {
      package MyClassWithDSL;
      use Moo;                      # or Moose
      with qw(MooX::Role::WithDSL);

      sub _build_dsl_keywords { [ qw(add_values) ] };

      has values => (is => 'ro',
                     default => sub { [] },
                    );

      sub add_values {
          my $self = shift;
          push @{$self->values}, @_;
      }
    }

    # make a new instance
    my $dsl = MyClassWithDSL->new();

    my $code = <<EOC;
    add_values(qw(2 1));
    add_values(qw(3));
    EOC

    my $return_value = $dsl->instance_eval($code);
    cmp_deeply($dsl->values, bag(qw(1 2 3)), "Values were added");

    done_testing;


=head1 DESCRIPTION

This package implement a Moo{,se} compatible role that makes it easy to develop
domain specific languages (DSL's).  It provides a simple interface,
L</instance_eval>, for evaluating snippets of a DSL with respect to a
particular instance of a class that consumes the role.  The class specifies a
subset of its methods that become the routines in the DSL.  Each instance of
the class builds a private package containings curried versions of these
routines bound to that instance and has a routine for using C<eval> to execute
statements from the DSL in that package.

=cut

use Moo::Role;

use Data::OptList;
use MooX::Types::MooseLike::Base qw(ArrayRef CodeRef);
use Package::Stash;

=attr dsl_keywords

Returns an arrayref of dsl keywords.

Lazy, classes which consume the role are required to supply a builder named
C<_build_dsl_keywords>.

=requires _build_dsl_keywords

A subrouting (used as the Moo{,se} builder for the L</dsl_keywords> attribute)
that returns an array reference containing the list of methods that should be
used as keywords in the DSL.

=cut

has dsl_keywords => (
    is      => 'rw',
    isa     => ArrayRef,
    lazy    => 1,
    builder => 1,
    trigger => sub { $_[0]->clear__instance_evalator },
);

=attr _instance_evalator

PRIVATE

There is no 'u' in _instance_evalator.  That means there should be no
you in there either....

Returns a coderef that is used by the instance_eval() method.

=cut

has _instance_evalator => (
    is       => 'ro',
    isa      => CodeRef,
    lazy     => 1,
    builder  => 1,
    clearer  => 1,
    init_arg => undef,
);

{
    my $ANON_SERIAL = 0;

    sub _build_anon_pkg_name {
        return __PACKAGE__ . "::ANON_" . ++$ANON_SERIAL;
    }
}

##
## - set up an environment (anonymous package) in which to execute code that is
##   being instance_eval'ed,
## - push curried closures into the package for each of the closures,
## - and build a coderef that switches to that package, does the eval,
##   dies if the eval had trouble andotherwise returns the eval's return value.
##
sub _build__instance_evalator {
    my $self = shift;

    my $pkg_name = _build_anon_pkg_name();
    my $stash    = Package::Stash->new("$pkg_name");

    # make a set of closures for keywords that curry out the invocant
    # and add them to the package.
    my $keywords = Data::OptList::mkopt_hash( $self->dsl_keywords,
        { moniker => 'keyword list' }, ['HASH'], );

    # name/keyword pairs, DSL keyword is explicitly named or use method name.
    my @pairs = map { [ $_ => $keywords->{$_}->{as} || $_ ] } keys %$keywords;

    foreach my $pair (@pairs) {
        my $method  = $pair->[0];
        my $keyword = $pair->[1];

        my $coderef = sub {
            return $self->$method(@_);
        };

        die "Attempted to redefine method named \"$keyword\""
            if $stash->has_symbol("&$keyword");
        $stash->add_symbol( "&$keyword", $coderef );
    }

    my $coderef = sub {
        my $code   = "package $pkg_name; " . shift;
        my $result = eval $code;
        die $@ if $@;
        return $result;
    };

    return $coderef;
}

=method instance_eval

Something kind-a similar to Ruby's instance_eval.  Takes a string and evaluates
it using eval(), The evaluation happens in a package that has been populated
with a set of functions that map to methods in this class with the instance
curried out.

See the synopsis for an example.

=cut

sub instance_eval {
    my $self = shift;

    $self->_instance_evalator()->(@_);
}

requires qw(_build_dsl_keywords);

1;
