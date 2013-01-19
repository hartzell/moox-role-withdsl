package MooX::Role::WithDSL;
# ABSTRACT: Add DSL features to your class.

use Moo::Role;
use MooX::Types::MooseLike::Base qw(ArrayRef CodeRef);

has dsl_keywords => ( is => 'rw',
                      isa => ArrayRef,
                    );

has instance_evalator => ( builder => 1, # _build_instance_evalator
                           init_arg => undef,
                           is => 'ro',
                           isa => CodeRef,
                           lazy => 1,
                         );

sub _build_instance_evalator {
  my $self = shift;
  my $coderef =  sub { my $value = shift;
                       $self->value($value);
                     };
  return $coderef;
}

sub instance_eval {
  my $self = shift;
#  my $coderef = $self->instance_evalator();
#  $coderef->(@_);
  $self->instance_evalator()->(@_);
};

1;
