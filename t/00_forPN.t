# -*- cperl -*-

use Test::More tests => 4;



use locale;
use Lingua::PT::PLN;
use Data::Dumper;

$a = 'à';

SKIP: {
  skip "not a good locale", 4 unless $a =~ m!^\w$!;

  my $count=0;
  my %pnlist=();
  my $countD=0;
  my %pnlistD=();

  forPN({in=>"t/00_oco.ex"},
	sub{$pnlist{n($_[0])}++; $count++});

  is( $count, "322","forPN");
  is( $pnlist{Portugal}, "5","forPN");
  is( $pnlist{"Pimenta Machado"}, "4","forPN");
  is( $pnlist{"Ribeiro da Silva"}, "1","forPN");

  sub n{
    my $a=shift;
    for($a){s/\s+/ /g; s/^ //; s/ $//;}
    $a;
  }
}
1;

__END__

forPN({in=>"t/00_oco.ex", t=> "double", sep=> '>', out=> "___" },
      sub{"<PN>$_[0]</PN>"},
      sub{"<PN d='1'>$_[0]</PN>"});
unlink("___");



$count=0;
%pnlist=();
$countD=0;
%pnlistD=();

forPN({in=>"t/00_oco.ex", t=> "double", sep=> '>' },
      sub{$pnlist{n($_[0])}++; $count++},
      sub{$pnlistD{n($_[0])}++; $countD++});

open(F,">___");
print F Dumper(\%pnlist,\%pnlistD);
close F;


is( $count, "314","forPN");
is( $pnlist{Portugal}, "5","forPN");
is( $pnlist{"Pimenta Machado"}, "4","forPN");
is( $pnlist{"Ribeiro da Silva"}, "1","forPN");

is( $countD, "80","forPN");
is( $pnlistD{Portugal}, "15","forPN");
is( $pnlistD{"Manuel Sérgio"}, "111","forPN");
is( $pnlistD{"Víctor de Sá"}, "1111","forPN");
