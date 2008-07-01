package Lingua::PT::PLN;

use strict;

use Lingua::PT::PLNbase;

require Exporter;
our @ISA = qw(Exporter AutoLoader);

our @EXPORT = 
  (@Lingua::PT::PLNbase::EXPORT,
   qw(syllable accent wordaccent oco));
our $VERSION = '0.15';

use POSIX qw(locale_h);
setlocale(&POSIX::LC_ALL, "pt_PT");
use locale;

our ($consoante, $vogal, $acento, %names);

my ($lmax,$maxlog,$magicF);

BEGIN {
  $consoante=qr{[bcçdfghjklmñnpqrstvwyxz]}i;
  $vogal=qr{[áéíóúâêôãõàèaeiouüöäë]}i;
  $acento=qr{[áéíóúâêôãõüöäë]}i;
  setlocale(&POSIX::LC_ALL, "pt_PT");

  use POSIX;
  POSIX::setlocale(LC_CTYPE,"pt_PT");

  $lmax = 1000000;
  $maxlog = 13.815;
  $magicF = $maxlog/log($lmax);
}



sub oco {
  ### { from => (file|string),
  ###    num => 1,
  ###    log => 1,    # logaritmic output 
  ###  alpha => 1,
  ### output => file,
  ### encoding => utf8,
  ### ignorexml => 1,
  ### ignorecase => 1}

  my %opt = (from => 'file', ignorecase => 0, ignorexml => 0, encoding => "latin1");
  %opt = (%opt , %{shift(@_)}) if ref($_[0]) eq "HASH";

  local $\ = "\n";                    # set output record separator

  my $P="(?:[,;:?!]|[.]+|[-]+)";      # pontuacao a contar
  my $A="[A-ZñÑa-záàãâçéèêíóòõôöúùûüÁÀÃÂÇÉÈÊÍÓÒÕÔÚÙÛÜÖ_]";
  my $I="[ \"(){}+*=<>\250\256\257\277\253\273]"; # car. a  ignorar
  my %oco=();
  my $tot=0;

  if ($opt{from} eq 'string') {
    my (@str) = (@_);
    for (@str) {
      $_ = lc if $opt{ignorecase};
      s/<[^>]+>//g if $opt{ignorexml};
      for (/($A+(?:['-]$A+)*|$P)/g) { $oco{$_}++; $tot++ }
    }
  } else {
    my (@file) = (@_);
    for(@file) {
      open F,"< $_" or die "cant open $_: $!";
      binmode(F, ":utf8") if $opt{encoding} =~ /utf8/i ;
      while (<F>) {
	$_ = lc if $opt{ignorecase};
	s/<[^>]+>//g if $opt{ignorexml};
	for (/($A+(?:['-]$A+)*|$P)/g) { $oco{$_}++;  $tot++}
      }
      close F;
    }
  }

  if ($opt{log}){
    print "total = $tot\n";
    _setmax($tot);
    _setmax($opt{log}) if($opt{log} > 1);
    for (keys %oco){
      $oco{$_}=_logit($oco{$_});
    }
  }

  if ($opt{num}) { # imprime por ordem de quantidade de ocorrencias

    # TODO: não é portável
    if (defined $opt{output}) {
      open SORT,"| sort -nr > $opt{output}"
    } else {
      open SORT,"| sort -nr"
    }

    for my $i (keys %oco) {
      print SORT "$oco{$i} $i"
    }
    close SORT;

  } elsif ($opt{alpha}) { # imprime ordenado alfabeticamente

    if (defined $opt{output}) {
      open SORT ,"> $opt{output}";
      for my $i (sort keys %oco ) {
	print SORT  "$i $oco{$i}";
      }
    } else {
      for my $i (sort keys %oco ) {
	print  "$i $oco{$i}";
      }
    }
  } else {
    return (%oco)
  }
}

### syllabs, and accents

sub accent {
  local $/ = "";           # input record separator=1 or more empty lines
  my $p=shift;
  $p =~ s/(\w+)/ wordaccent($1) /ge;
  $p
}

sub wordaccent {
  my $p = syllable(shift);
  for ($p) {
    s/(\w*$acento)/"$1/i             or  # word with an accent character
      s/(\w*)([ua])(ir)$/$1$2|"$3/i  or  # word ending with air uir
      s/(\w*([zlr]|[iu]s?))$/"$1/i   or  # word ending with z l r i u is us
      s/(\w+\|\w+)$/"$1/             or  # accent in 2 syllable frm the end
      s/(\w)/"$1/;                       # accent in the only syllable

    s/"(([qg]u|$consoante)*($vogal|[yw]))/$1:/i ; # accent in the 1.st vowel
    s/:($acento)/$1:/i  ;                         # mv accent after accents
    s/"//g;

  }
  $p
}

my %syl = (
   20 => " -.!?:;",
   10 => "bçdfgjkpqtv",
   8 => "sc",
   7 => "m",
   6 => "lzx",
   5 => "nr",
   4 => "h",
   3 => "wy",
   2 => "eaoáéíóúôâêûàãõäëïöü",
   1 => "iu",
   breakpair =>
      #"ie|ia|io|ee|oo|oa|sl|sm|sn|sc|sr|rn|bc|lr|lz|bd|bj|bg|bq|bt|bv|pt|pc|dj|pç|ln|nr|mn|tp|bf|bp",
      "sl|sm|sn|sc|sr|rn|bc|lr|lz|bd|bj|bg|bq|bt|bv|pt|pc|dj|pç|ln|nr|mn|tp|bf|bp",
  );

my %spri = ();

for my $pri (grep(/\d/, keys %syl)){
  for(split(//,$syl{$pri})) { $spri{$_} = $pri}}

(my $sylseppair= $syl{breakpair}) =~ s/(\w)(\w)/(\?<=($1))(\?=($2))/g;

sub syllable{
  my $p=shift;

  for($p){
    s/$sylseppair/|/g;
    s{(\w)(?=(\w)(\w))}
      {if($spri{lc($1)}<$spri{lc($2)} && $spri{lc($2)}>=$spri{lc($3)}){"$1|"}
       else{$1}
      }ge;

    s{([a])(i[ru])}{$1|$2}i;              #ditongos and friends
    s{([ioeê])([aoe])}{$1|$2}ig;
    s{u(ai|ou)}{u|$1}i;
    s{([^qg]u)(ei|iu|ir|$acento)}{$1|$2}i;
    s{([aeio])($acento)}{$1|$2}i;
    s{([íúô])($vogal)}{$1|$2}i;

    s{([qg]u)\|([ei])}{$1$2}i;
    s{^($consoante)\|}{$1}i;
    s{êm$}{ê|_nhem}i;
  }
  $p
}

sub compara {
  # ordena pela lista de palavras invertida
  join(" ", reverse(split(" ",$a))) cmp join(" ", reverse(split(" ",$b)));
}

sub compacta {
  my $s;
  my $p = shift;
  my $r = $p;
  my $q = $names{$p};
  while ($s = shift) {
    if ($s =~ (/^(.+) $p/))
      {
	$r = "($1) $r" ;
	$q += $names{$s};
      }
    else
      {
	print "$r - $q";
	$r = $s;
	$q = $names{$s};
      }
    $p=$s;
  }
  print "$r - $q";
}

my %savit_p = ();
my $savit_n = 0;

sub _savit {
  my $a = shift;
  $savit_p{++$savit_n} = $a ;
  " __MARCA__$savit_n "
}

sub _loadit {
  my $a = shift;
  $a =~ s/ ?__MARCA__(\d+) ?/$savit_p{$1}/g;
  $savit_n = 0;
  $a;
}

1;

#sub setlogmax{
# $maxlog = shift;
# $magicF=$maxlog/log($lmax);
###  print "Debud .... Maxlog=$maxlog; magic=$magicF\n";
#}

sub _setmax{
 $lmax = shift;
 $magicF=$maxlog/log($lmax);
##  print "Debud .... Max=$lmax; magic=$magicF\n";
}

sub _logit{
  my $n=shift;
  return 0 unless $n;
##  print STDERR "...$n,", log($n*$magicF) ,"\n" ;
  log($n)*$magicF
}

1;

__END__

$lm='[a-záéíóúâêôàãõçüöñ]';                      # letra minuscula
$lM='[A-ZÁÉÍÓÚÂÊÔÀÃÕÇÜÖÑ]';                      # letra Maiuscula
$l1='[A-ZÁÉÍÓÚÂÊÔÀÃÕÇÜÖÑa-záéíóúâêôàãõçüöñ0-9]'; # letra e numero
$c1='[^»a-záéíóúâêà,;?!)]';


=head1 NAME

Lingua::PT::PLN - Perl extension for NLP of the Portuguese Language

=head1 SYNOPSIS

  use Lingua::PT::PLN;

  # occurrence counter
  %o = oco("file");
  oco({num=>1,output=>"outfile"},"file");

  $p = accent($phrase);        ## mark word accent of all words

  $w = syllable($word);
  $w = wordaccent($word);

=head1 DESCRIPTION

This is a module for Natural Language Processing of the Portuguese.

Because you are processing Portuguese, you must use a correct locale.

=head2 Occurrence counting: C<oco>

Counts word occurrence from a string or a set of files. Returns an
hash with the information or creates a sorted file with the results.

This function takes optionally as first argument an hash of options
where you can specify:

=over 4

=item num => 1

means the output should be sorted by ocurrence number;

=item alpha => 1

mean the output should be sorted lexicographically

=item output => "f"

means the output will be written to the file "f";

=item from => "string"

means that next argument (after the option hash) is a string which
should be used as input for the function.

=item from => "file"

means that remaining arguments to the function are filenames which
should be used as input for the function. This is the default option.
  
=item encoding => "utf8"

To force UTF8 encoding (default latin1)

=item ignorexml => 1

XML tags are striped.

=item ignorecase => 1

All words are lower-cased.

=item log => 1

to obtain logaritmic output. Output values are between 0..log(1000000) 
or (0..13.85).

  log => 20    -- to obtain values between 0 and 20

=back

Examples:

  oco({num=>1,output=>"f"}, "f1","f2")
  # sort by occurrence
  # store output on file "f"
  # process files "f1" and "f2"

  oco({alpha=>1,output=>"f"}, "f1","f2")
  # sort lexicographically
  # store output on file "f"
  # process files "f1" and "f2"

  %oc = oco("f1","f2")
  # return a hash with the occurrences
  # use "f1" and "f2" as input files

  %oc = oco( {from=>"string"},"text in a string")
  # use a string as input
  # return a hash with the occurrences

=head2 C<syllable>

  my $sylls = syllable( $word )

Returns the word with the syllables separated by "|"

=head2 accent

  my $accent = accent( $phrase )

Returns the phrase with the syllables separated by "|" and accents marked with
the charater ":".

=head2 wordaccent

Retuns the word splited into syllables and with the accent character marked.

=head2 compacta

=head2 compara

=head1 AUTHOR

Projecto Natura (http://natura.di.uminho.pt)

Alberto Simoes (albie@alfarrabio.di.uminho.pt)

José João Almeida (jj@di.uminho.pt)

Paulo Rocha (paulo.rocha@di.uminho.pt)

=head1 SEE ALSO

Lingua::PT::PLNbase(3pm),
perl(1),
cqp(1),

=cut
