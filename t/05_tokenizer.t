# -*- cperl -*-

use Test::More tests => 1 + 10;
use Lingua::PT::PLN;

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


1;
