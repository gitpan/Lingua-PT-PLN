# -*- cperl -*-

use Test::More tests => 1;
use Lingua::PT::PLN;

my $txt = Lingua::PT::PLN::tratar_pontuacao_interna("Eu chamo-me jj");

is($txt, "Eu chamo-me Jose Joao");


1;
