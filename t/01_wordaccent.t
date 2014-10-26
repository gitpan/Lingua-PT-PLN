# -*- cperl -*-

use Test::More tests => 30;
use Lingua::PT::PLN;

is( syllable("ol�")  , "o|l�"   ,"syllable");
is( wordaccent("ol�")  , "o|l�:"   ,"wordaccent");
is( wordaccent("ol�", 1)  , "o|\"l�"   ,"wordaccent");

is( syllable("casa")  , "ca|sa"   ,"syllable");
is( wordaccent("casa")  , "ca:|sa"   ,"wordaccent");
is( wordaccent("casa", 1)  , "\"ca|sa"   ,"wordaccent");

is( syllable("beb�")  , "be|b�"   ,"syllable");
is( wordaccent("beb�")  , "be|b�:"   ,"wordaccent");
is( wordaccent("beb�", 1)  , "be|\"b�"   ,"wordaccent");

is( syllable("continue")  , "con|ti|nu|e"   ,"syllable");
is( wordaccent("continue")  , "con|ti|nu:|e"   ,"wordaccent");
is( wordaccent("continue", 1)  , "con|ti|\"nu|e"   ,"wordaccent");

is( syllable("quota")  , "quo|ta"   ,"syllable");
is( wordaccent("quota")  , "quo:|ta"   ,"wordaccent");
is( wordaccent("quota", 1)  , "\"quo|ta"   ,"wordaccent");

is( syllable("v�cuo")  , "v�|cu|o"   ,"syllable");
is( wordaccent("v�cuo")  , "v�:|cu|o"   ,"wordaccent");
is( wordaccent("v�cuo", 1)  , "\"v�|cu|o"   ,"wordaccent");

is( syllable("op��o")  , "op|��o"   ,"syllable");
is( wordaccent("op��o")  , "op|��:o"   ,"wordaccent");
is( wordaccent("op��o", 1)  , "op|\"��o"   ,"wordaccent");

is( syllable("aonde")  , "a|on|de"   ,"syllable");
is( wordaccent("aonde")  , "a|o:n|de"   ,"wordaccent");
is( wordaccent("aonde", 1)  , "a|\"on|de"   ,"wordaccent");

is( syllable("aer�dromo")  , "a|e|r�|dro|mo"   ,"syllable");
is( wordaccent("aer�dromo")  , "a|e|r�:|dro|mo"   ,"wordaccent");
is( wordaccent("aer�dromo", 1)  , "a|e|\"r�|dro|mo"   ,"wordaccent");

is( syllable("hist�ria")  , "his|t�|ri|a"   ,"syllable");
is( wordaccent("hist�ria")  , "his|t�:|ri|a"   ,"wordaccent");
is( wordaccent("hist�ria", 1)  , "his|\"t�|ri|a"   ,"wordaccent");

1;
