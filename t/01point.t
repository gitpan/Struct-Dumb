#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Fatal;

use Struct::Dumb;

struct Point => [qw( x y )];

my $point = Point(10, 20);
ok( ref $point, '$point is a ref' );

can_ok( $point, "x" );

is( $point->x, 10, '$point->x is 10' );

$point->y = 30;
is( $point->y, 30, '$point->y is 30 after mutation' );

like( exception { $point->z },
      qr/^main::Point does not have a 'z' field at \S+ line \d+\n/,
      '$point->z throws exception' );

like( exception { Point(30) },
      qr/^usage: main::Point\(\$x, \$y\) at \S+ line \d+\n/,
      'Point(30) throws usage exception' );
