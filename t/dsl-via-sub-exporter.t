#!perl

use strict;
use warnings;
use Test::More;

### invoke import on an instance
###   create an anonymous package
###   use into to install things into that package
###   create an evalator that calls eval in that package space.
###   stash that eval in the instances instance_evalator attr
### call $o->instance_eval ==> call the code stashed in the evalator

{

    package MyDSL;

    use Moo;
    use MooX::Types::MooseLike::Base qw(ArrayRef CodeRef Str);

    use Package::Stash;

    use Sub::Exporter -setup => {

        #groups => { dsl_routines => \'_export_keywords',
        groups     => { default => \'_export_keywords', },
        collectors => [qw( keywords )],
    };

    has evalator => (
        builder => "_build_evalator",
        is      => "ro",
        isa     => CodeRef,
        lazy    => 1,
    );

    {
        my $ANON_SERIAL = 0;

        sub _build_anon_pkg_name {
            return __PACKAGE__ . "::ANON_" . ++$ANON_SERIAL;
        }

        sub _build_evalator {
            my $self     = shift;
            my $pkg_name = _build_anon_pkg_name();
            my $pkg      = Package::Stash->new($pkg_name);

            #      $self->_setup_dsl(keywords => $self->dsl_keywords);
            $self->import( { into => $pkg_name, },
                '-default', keywords => [qw(value print_value)] );

      # build an routine that evals code in pkg, return code ref from builder;
            my $coderef = sub {
                my $code = shift;
                my $result;
                $code   = "package $pkg_name; " . $code;
                $result = eval $code;
                die $@ if $@;
                return $result;
            };
            return $coderef;
        }
    }

    sub _export_keywords {
        my ( $class, $name, $arg, $col ) = @_;
        my $hash_ref;

        foreach my $method ( @{ $col->{keywords} } ) {
            $hash_ref->{$method} = sub { $class->$method(@_) };
        }

        print "YIKES\n";
        return $hash_ref;
    }

    has value => (
        is  => "rw",
        isa => Str,
    );

    sub print_value {
        my $self = shift;
        print "The value is: " . $self->value . "\n";
    }

    sub instance_eval {
        my $self = shift;

        $self->evalator()->(@_);
    }
}

my $dsl = MyDSL->new();
$dsl->instance_eval('value(20)');

is( $dsl->value(), 20, "Got correct value" );

done_testing;
