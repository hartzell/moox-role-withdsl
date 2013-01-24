
use strict;
use warnings;
use Test::More;

{

    package Cypher;
    use Sub::Exporter::Util 'curry_method';
    use Sub::Exporter -setup => {
        exports => [ encypher     => curry_method ],
        groups  => { dsl_routines => \'apeshit', },
        -as     => 'monkey',
    };

    sub new { return bless {}, $_[0] }

    sub encypher {
        my $self = shift;
        print join ", ", @_;
        print "\n";
    }

    sub apeshit {
        my ( $class, $name, $arg, $col ) = @_;
        my $hash_ref;
        my $cypher = $class->new();

        foreach my $method (qw(name print_a print_b )) {
            $hash_ref->{$method} = sub { $cypher->$method(@_) };
        }

        $DB::single = 1;
        print "YIKES\n";
        return $hash_ref;
    }

    sub name { my $self = shift; $self->{name} = shift; }

    sub print_a {
        my $self = shift;
        print "a: " . $self->{name} . "\n";
    }
    sub print_b { my $self = shift; print "b: " . $self->{name} . "\n"; }
}

Cypher->monkey('-dsl_routines');

$DB::single = 1;

done_testing;

__END__

