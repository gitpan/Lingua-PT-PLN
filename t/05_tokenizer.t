# -*- cperl -*-

use Test::More tests => 11;
use locale;
use Lingua::PT::PLN;

$a = 'à';

SKIP: {
  skip "not a good locale", 11 unless $a =~ m!^\w$!;


  $/ = "\n\n";


  my $input = "";
  my $output = "";
  open T, "t/tokenizer" or die "Cannot open tests file";
  while(<T>) {
    chomp($input = <T>);
    chomp($output = <T>);


    my $tok2 = tokenize($input); # Braga
    is($tok2, $output);
  }
  close T;
}


1;
