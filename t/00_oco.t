# -*- cperl -*-

use Test::More tests => 7;
use Lingua::PT::PLN;

my %o = oco({from=>"file"},"t/00_oco.ex");

is( $o{primeiro}  , 5  ,"oco from file");
is( $o{dos}       , 38  ,"oco from file");
is( $o{"roll-off"}, 2  ,"oco from file");

%o = oco({from=>"string"},
          "era era era uma vez, lindo um gato malt�s, um lindo gato");

is( $o{era}       , 3  ,"oco from string");
is( $o{um}        , 2  ,"oco from string");
is( $o{rum}       , undef  ,"oco from string");
is( $o{"malt�s"}  , 1  ,"oco from string");

1;
