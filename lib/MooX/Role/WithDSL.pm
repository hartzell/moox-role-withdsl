package MooX::Role::WithDSL;
# ABSTRACT: Add DSL features to your class.

use Moo::Role;

use MooX::Types::MooseLike::Base qw(ArrayRef CodeRef);
use Package::Stash;



=attr dsl_keywords

Returns a list of dsl keywords.

=cut

has dsl_keywords => ( is => 'rw',
                      isa => ArrayRef,
                      lazy => 1,
                      trigger => sub { $_[0]->clear__instance_evalator },
                    );


=attr _instance_evalator

PRIVATE

There is no 'u' in _instance_evalator.  That means you should not be in their either....

Returns a coderef

=cut

has _instance_evalator => ( builder => 1, # _build__instance_evalator
                            clearer => 1,
                            init_arg => undef,
                            is => 'ro',
                            isa => CodeRef,
                            lazy => 1,
                          );


{
  my $ANON_SERIAL = 0;

  sub _build_anon_pkg_name { return __PACKAGE__ . "::ANON_" . ++$ANON_SERIAL; }

  sub _build__instance_evalator {
    my $self = shift;

    my $pkg_name = _build_anon_pkg_name();
    my $stash = Package::Stash->new("$pkg_name");

    foreach my $keyword (@{$self->dsl_keywords}) {
      my $coderef = sub {
        return $self->$keyword(@_);
      };
      $stash->add_symbol("&$keyword", $coderef);
    }

    $DB::single = 1;

    my $coderef = sub { my $code = shift;
                        my $result;
                        $code = "package $pkg_name; " . $code;
                        $result = eval $code;
                        $DB::single = 1;
                        return $result;
                      };

    $stash->add_symbol("&evalator", $coderef);

    return $coderef;
  }

}

sub instance_eval {
  my $self = shift;

  $self->_instance_evalator()->(@_);
};

1;
