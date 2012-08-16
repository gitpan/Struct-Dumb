#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012 -- leonerd@leonerd.org.uk

package Struct::Dumb;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;

use Exporter 'import';
our @EXPORT = qw(
   struct
);
our @EXPORT_OK = qw(
   readonly_struct
);

=head1 NAME

C<Struct::Dumb> - make simple lightweight record-like structures

=head1 SYNOPSIS

 use Struct::Dumb;
 
 struct Point => [qw( x y )];

 my $point = Point(10, 20);

 printf "Point is at (%d, %d)\n", $point->x, $point->y;

 $point->y = 30;
 printf "Point is now at (%d, %d)\n", $point->x, $point->y;

=head1 DESCRIPTION

C<Struct::Dumb> creates record-like structure types, similar to the C<struct>
keyword in C, C++ or C#, or C<Record> in Pascal. An invocation of this module
will create a construction function which returns new object references with
the given field values. These references all respond to lvalue methods that
access or modify the values stored.

It's specifically and intentionally not meant to be an object class. You
cannot subclass it. You cannot provide additional methods. You cannot apply
roles or mixins or metaclasses or traits or antlers or whatever else is in
fashion this week.

On the other hand, it is tiny, creates cheap lightweight array-backed
structures, uses nothing outside of core. It's intended simply to be a
slightly nicer way to store data structures, where otherwise you might be
tempted to abuse a hash, complete with the risk of typoing key names. The
constructor will C<croak> if passed the wrong number of arguments, as will
attempts to refer to fields that don't exist.

 $ perl -E 'use Struct::Dumb; struct Point => [qw( x y )]; Point(30)'
 usage: main::Point($x, $y) at -e line 1

 $ perl -E 'use Struct::Dumb; struct Point => [qw( x y )]; Point(10,20)->z'
 main::Point does not have a 'z' field at -e line 1

=cut

=head1 FUNCTIONS

=cut

sub _struct
{
   my ( $name, $fields, $caller, $lvalue ) = @_;

   my $pkg = "${caller}::$name";

   my %subs;
   foreach ( 0 .. $#$fields ) {
      my $idx = $_;
      $subs{$fields->[$idx]} = $lvalue ? sub :lvalue { shift->[$idx] }
                                       : sub { shift->[$idx] };
   }
   $subs{DESTROY} = sub {};
   $subs{AUTOLOAD} = sub {
      my ( $field ) = our $AUTOLOAD =~ m/::([^:]+)$/;
      croak "$pkg does not have a '$field' field";
   };

   my $fieldcount = @$fields;
   my $argnames = join ", ", map "\$$_", @$fields;
   my $constructor = sub {
      @_ == $fieldcount or croak "usage: $pkg($argnames)";
      bless [ @_ ], $pkg;
   };

   no strict 'refs';
   *{"${pkg}::$_"} = $subs{$_} for keys %subs;
   *{"${caller}::$name"} = $constructor;
}

=head2 struct $name => [ @fieldnames ]

Creates a new structure type. This exports a new function of the type's name
into the caller's namespace. Invoking this function returns a new instance of
a type that implements those field names, as accessors and mutators for the
fields.

=cut

sub struct
{
   _struct( $_[0], $_[1], scalar caller, 1 );
}

=head2 readonly_struct $name => [ @fieldnames ]

Similar to C<struct>, but instances of this type are immutable once
constructed. The field accessor methods will not be marked with the
C<:lvalue> attribute.

=cut

sub readonly_struct
{
   _struct( $_[0], $_[1], scalar caller, 0 );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
