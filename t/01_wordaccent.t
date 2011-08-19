# -*- cperl -*-

use Test::More tests => 30;
use Lingua::PT::PLN;

is( syllable("olá")  , "o|lá"   ,"syllable");
is( wordaccent("olá")  , "o|lá:"   ,"wordaccent");
is( wordaccent("olá", 1)  , "o|\"lá"   ,"wordaccent");

is( syllable("casa")  , "ca|sa"   ,"syllable");
is( wordaccent("casa")  , "ca:|sa"   ,"wordaccent");
is( wordaccent("casa", 1)  , "\"ca|sa"   ,"wordaccent");

is( syllable("bebé")  , "be|bé"   ,"syllable");
is( wordaccent("bebé")  , "be|bé:"   ,"wordaccent");
is( wordaccent("bebé", 1)  , "be|\"bé"   ,"wordaccent");

is( syllable("continue")  , "con|ti|nu|e"   ,"syllable");
is( wordaccent("continue")  , "con|ti|nu:|e"   ,"wordaccent");
is( wordaccent("continue", 1)  , "con|ti|\"nu|e"   ,"wordaccent");

is( syllable("quota")  , "quo|ta"   ,"syllable");
is( wordaccent("quota")  , "quo:|ta"   ,"wordaccent");
is( wordaccent("quota", 1)  , "\"quo|ta"   ,"wordaccent");

is( syllable("vácuo")  , "vá|cu|o"   ,"syllable");
is( wordaccent("vácuo")  , "vá:|cu|o"   ,"wordaccent");
is( wordaccent("vácuo", 1)  , "\"vá|cu|o"   ,"wordaccent");

is( syllable("opção")  , "op|ção"   ,"syllable");
is( wordaccent("opção")  , "op|çã:o"   ,"wordaccent");
is( wordaccent("opção", 1)  , "op|\"ção"   ,"wordaccent");

is( syllable("aonde")  , "a|on|de"   ,"syllable");
is( wordaccent("aonde")  , "a|o:n|de"   ,"wordaccent");
is( wordaccent("aonde", 1)  , "a|\"on|de"   ,"wordaccent");

is( syllable("aeródromo")  , "a|e|ró|dro|mo"   ,"syllable");
is( wordaccent("aeródromo")  , "a|e|ró:|dro|mo"   ,"wordaccent");
is( wordaccent("aeródromo", 1)  , "a|e|\"ró|dro|mo"   ,"wordaccent");

is( syllable("história")  , "his|tó|ri|a"   ,"syllable");
is( wordaccent("história")  , "his|tó:|ri|a"   ,"wordaccent");
is( wordaccent("história", 1)  , "his|\"tó|ri|a"   ,"wordaccent");

1;
