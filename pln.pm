package Lingua::PT::pln;

#use strict;
#use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw(

   getPN	
   printPN	
   printPNstring
   forPN
   forPNstring

   syllabe
   accent
   wordaccent

   xmlsentences
   sentences

   cqptokens
   oco
);
$VERSION = '0.02';

# printPN  - extrai os nomes próprios dum texto.
#   -comp    junta certos nomes: Fermat + Pierre de Fermat = (Pierre de) Fermat
#   -prof
#   -e       "Sebastiao e Silva" "e" como pertencente a PN
#   -em     "em Famalicão" como pertencente a PN
use locale;

my ($conso, $vogal);
BEGIN{

$conso='[bcdfghjklmnpqrstvwyxzç]';
$vogal='[áéíóúôâêãõàaeiou]';

$np1='(?:[A-ZÉÚÓÁÂ][.]|[sS]r[.]|[dD]r[.]|St[oa]?[.]|[A-ZÉÚÓÁÂ]\w+(?:-\w+)*)';

if ($e){
  $np="$np1(?:\\s+(?:d[eao]s?\\s+|e\\s+)?$np1)*|(?:[«\x93].{1,40}?[»\x94])";}
else { $
  np="$np1(?:\\s+(?:d[eao]s?\\s+)?$np1)*|(?:[«\x93].{1,40}?[»\x94])";}

@stopw= qw{
no com se em segundo a o os as na nos nas do das dos da tanto
para de desde mas quando esta sem nem só apenas mesmo até uma uns um
pela por pelo pelas pelos depois ao sobre como umas já enquanto aos
também amanhã ontem embora essa nesse olhe
primeiro simplesmente era foi é será são seja
chama-se chamam-se subtitui resta diz salvo disse diz
};

sub oco{
local $\ = "\n";           # set output record separator
my $P="[.,;:?!]";          # pontuacao a contar
my $A="[A-ZñÑa-záàãâçéèêíóòõôúùûÁÀÃÂÇÉÈÊÍÓÒÕÔÚÙÛ-]";
my $I="[ \"(){}+*=<>\250\256\257\277\253\273]"; # car. a  ignorar
my %op = ();
my %oco=();
 
if(ref($_[0]) eq "HASH"){
  my $arg=shift;
  %op = (%op , %$arg);}
my (@file) = (@_); 
for(@file){
  open(F,"< $_") or die("cant open $_");
  while (<F>) {
    for (/($A+|$P+)/g){ $oco{$_}++;}
  }
  close F;
}

if($op{num}){ # imprime por ordem de quantidade de ocorrencias
    if(defined $op{output}){ open(SORT,"| sort -nr > $op{output}");}
    else                   { open(SORT,"| sort -nr");}
    for $i (keys %oco) {print SORT "$oco{$i} $i"}
    close SORT;} 
elsif($op{alpha}){ # imprime ordenadamente
    if(defined $op{output}){ open(SORT ,"> $op{output}");
           for $i (sort keys %oco ) {print SORT  "$i $oco{$i}";}}
    else { for $i (sort keys %oco ) {print  "$i $oco{$i}";}} }
else {return (%oco)}
}

$prof=join("|", qw{
astrólogo
astrónomo
advogado
cantor
actor
baterista
compositor
dramaturgo
engenheiro
escritor
filósofo
flautista
físico
investigador
matemático
médico
ministro
músico
químico
pianista
poeta
professor
teólogo
jogador
});

$adje=join("|", qw{
português
francês
inglês
espanhol
internacional
bracarence
minhoto
});

$sep1=join("|", qw{
chamado
"conhecido como"
});

$sep2=join("|", qw{
brilhante
conhecido
reputado
popular
});

@vazia{@stopw}=(@stopw);    #para ser mais facil ver se uma pal 'e vazia
$em = '\b(?:[Ee]m|[nN][oa]s?)';
}

sub forPN{
local $/ = "";           # input record separator=1 or more empty lines
  my $f=shift;
  die("invalid parameter") unless (ref($f) eq "CODE");
  while (<>) {
     $ctx=$_;
     s/(\w+\s+|[«»,()'`i"]\s*)($np)/$1 . &{$f}($2,$ctx)/ge       ;
     print;
  }
}

sub forPNstring{
  my $f=shift;
  die("invalid parameter: function expected") unless (ref($f) eq "CODE");
  my $text = shift;
  my $sep = shift || "\n";
  my $r = '';
  for (split(/$sep/,$text)){
     $ctx=$_;
     s/(\w+\s+|[«»,()'`i"]\s*)($np)/$1 . &{$f}($2,$ctx)/ge       ;
     $r .= "$_$sep";
  }
  $r;
}

sub printPNstring{
  my $text = shift;
  my %opt;
  @opt{@_} = @_;
  my (%profissao,%names,%namesduv);

  for($text){
    chop;
    s/\n/ /g;
    for (/[.?!:;"]\s+($np1\s+$np)/gxs)     { $namesduv{$_}++;}
    for (/[)>(«]\s*($np1\s+$np)/gxs)       { $namesduv{$_}++;}
    for (/(?:[\w«»,]\s+)($np)/gxs)         { $names{$_}++;}
    if ($opt{em}) { for (/$em\s+($npxs)/g) { $gnames{$_}++;}}
    if ($opt{prof}) {
       while(/\b($prof)\s+(?:(?:$sep1)\s+)?($np)/g)   {$profissao{$2}=$1;}
       while(/(?:[\w«»,]\s+|[(])($np),\s*(?:(?:$sep2)\s+)?($prof)/g)
            {$profissao{$1}=$2;}
    }
  }

  #tratamento dos nomes "duvidosos" = Nome prop no inicio duma frase
  #

  for (keys %namesduv){
     if(/^(\w+)/ && $vazia{lc($1)} )   #exemplo "Como Jose Manuel"
        { s/^\w+\s*//;                  # retira-se a 1.a palavra
          $names{$_}++;}
     else
        { $names{$_}++;}
  }
  if($opt{oco}){
       for (sort {$names{$b} <=> $names{$a}} keys %names )
           {printf("%60s - %d\n", $_ ,$names{$_});}
  }
  else{ if($opt{comp}){my @l = sort compara keys %names;
                       compacta(@l); }
        else{for (sort compara keys %names )
               {printf("%60s - %d\n", $_ ,$names{$_});} }

        if($opt{prof}){print "\nProfissões\n";
             for (keys %profissao){print "$_ -- $profissao{$_}";} }

        if($opt{em}){print "\nGeograficos\n";
            for (sort compara keys %gnames )
               {printf("%60s - %d\n", $_ ,$gnames{$_});} }
  }
}

sub getPN{
local $/ = "";           # input record separator=1 or more empty lines
  my %opt;
  @opt{@_} = @_;
  my (%profissao,%names,%namesduv);
  while (<>) {
    chop;
    s/\n/ /g;
    for (/[.?!:;"]\s+($np1\s+$np)/g)     { $namesduv{$_}++;}
    for (/[)>(«]\s*($np1\s+$np)/g)       { $namesduv{$_}++;}
    for (/(?:[\w«»,]\s+)($np)/g)         { $names{$_}++;}
    if ($opt{em}) { for (/$em\s+($np)/g) { $gnames{$_}++;}}
    if ($opt{prof}) {
       while(/\b($prof)\s+(?:(?:$sep1)\s+)?($np)/g)   {$profissao{$2}=$1;}
       while(/(?:[\w«»,]\s+|[(])($np),\s*(?:(?:$sep2)\s+)?($prof)/g)
            {$profissao{$1}=$2;}
    }
  }

  #tratamento dos nomes "duvidosos" = Nome prop no inicio duma frase
  #

  for (keys %namesduv){
     if(/^(\w+)/ && $vazia{lc($1)} )    # exemplo "Como Jose Manuel"
        { s/^\w+\s*//;                  # retira-se a 1.a palavra
          $names{$_}++;}
     else
        { $names{$_}++;}
  }
  (%names)
}

sub printPN{
local $/ = "";           # input record separator=1 or more empty lines
  my %opt;
  @opt{@_} = @_;
  my (%profissao,%names,%namesduv);

  while (<>) {
    chop;
    s/\n/ /g;
    for (/[.?!:;"]\s+($np1\s+$np)/g)     { $namesduv{$_}++;}
    for (/[)>(«]\s*($np1\s+$np)/g)       { $namesduv{$_}++;}
    for (/(?:[\w«»,]\s+)($np)/g)         { $names{$_}++;}
    if ($opt{em}) { for (/$em\s+($np)/g) { $gnames{$_}++;}}
    if ($opt{prof}) {
       while(/\b($prof)\s+(?:(?:$sep1)\s+)?($np)/g)   {$profissao{$2}=$1;}
       while(/(?:[\w«»,]\s+|[(])($np),\s*(?:(?:$sep2)\s+)?($prof)/g)
            {$profissao{$1}=$2;}
    }
  }

  #tratamento dos nomes "duvidosos" = Nome prop no inicio duma frase
  #

  for (keys %namesduv){
     if(/^(\w+)/ && $vazia{lc($1)} )   #exemplo "Como Jose Manuel"
        {s/^\w+\s*//;                  # retira-se a 1.a palavra
         $names{$_}++;}
     else
        { $names{$_}++;}
  }

  if($opt{oco}){
       for (sort {$names{$b} <=> $names{$a}} keys %names )
           {printf("%6d - %s\n",$names{$_}, $_ );}
  }
  else{ if($opt{comp}){my @l = sort compara keys %names;
                       compacta(@l); }
        else{for (sort compara keys %names )
               {printf("%60s - %d\n", $_ ,$names{$_});} }

        if($opt{prof}){print "\nProfissões\n";
             for (keys %profissao){print "$_ -- $profissao{$_}";} }

        if($opt{em}){print "\nGeograficos\n";
            for (sort compara keys %gnames )
               {printf("%60s - %d\n", $_ ,$gnames{$_});} }
  }
}

sub accent{
local $/ = "";           # input record separator=1 or more empty lines
  my $p=shift;
  $p =~ s/(\w+)/ wordaccent($1) /ge;
  $p
}

sub wordaccent{
  my $p=syllabe(shift);
  for ($p){
    s/(\w*[áéíóúôâêãõ])/"$1/  or           # word with an accent character
    s/(\w*([zlr]|[iu]s?))$/"$1/  or        # word ending with z l r i u is us
    s/(\w+\|\w+)$/"$1/  or                 # accent in 2 syllabe frm the end
    s/(\w)/"$1/;                           # accent in the only syllabe

    s/"(($conso)*($vogal|[yw]))/$1:/;
    s/"//g;

  }
  $p
}

my %syl = (
 20 => " -.!?:;",
 10 => "bçdfgjkpqtv",
 7 => "sc",
 6 => "m",
 5 => "rnlzx",
 4 => "h",
 3 => "wy",
 2 => "eaoáéíóúôâêãõ",
 1 => "iu",
 breakpair => "ie|ia|io|ee|oo|oa|sl|sm|sn|sc|rn",
);

my %sylpri = ();
for my $pri (grep(/\d/, keys %syl)){
   for(split(//,$syl{$pri})) { $sylpri{$_} = $pri}}

(my $sylseppair= $syl{breakpair}) =~ s/(\w)(\w)/(\?<=($1))(\?=($2))/g;

sub syllabe{
  my $p=shift;

  for($p){
    s/$sylseppair/|/g;
    s{(\w)(?=(\w)(\w))}
     { if(     $sylpri{lc($1)} < $sylpri{lc($2)}
            && $sylpri{lc($2)} >= $sylpri{lc($3)} ) {"$1|"}
       else{$1}
     }ge;
  }
  $p
}

sub compara{     # ordena pela lista de palavras invertida
 join(" ", reverse(split(" ",$a))) cmp join(" ", reverse(split(" ",$b)));
}

sub compacta{
   my $p = shift;
   my $r = $p;
   my $q = $names{$p};
   while ($s = shift)
     { if ($s =~ (/^(.+) $p/)) { $r = "($1) $r" ;
                                 $q += $names{$s};
                               }
       else {print "$r - $q"; $r=$s; $q = $names{$s}; }
       $p=$s;
     }
   print "$r - $q";
}

my %savit_p = ();
my $savit_n = 0;

my $terminador='([.?!;:]+[»]?|<[pP]>|<br>)';

my $protect = '
       [\w_.-]+ \@ [\w_.-]+                      # emails
    |  <[^>]*>                                   # marcup XML SGML
    |  \d+(?:\.\d+)+                             # numbers
    |  \d+\:\d+                                  # the time
    |  ((https?|ftp|gopher)://|www)[\w_./~-]+    # urls
';

my $abrev = join '|', qw( srt?a? dra? [A-Z] etc exa? jr profs? arq av estr?
    et al vol eng tv lgo pr Oliv ig mrs? min rep );

sub xmlsentences{
local $/ = "";           # input record separator=1 or more empty lines
  my $par=shift;
  for($par){
      s/($protect)/savit($1)/xge;
      s#\b(($abrev)\.)#savit($1)#ige;
      s#($terminador)#$1</s>\n<s>#g;
      $_=loadit($_);
      s#</s>\n<s>\s*$##s;
  }
  "<s>$par</s>";
}

sub sentences{
my $MARCA="\0x01";
local $/ = "";           # input record separator=1 or more empty lines
  my $par=shift;
  for($par){
      s/($protect)/savit($1)/xge;
      s#\b(($abrev)\.)#savit($1)#ige;
#      s#($terminador)#$MARCA($1$MARCA)#g;
      s#($terminador)#$1$MARCA#g;
      $_=loadit($_);
#      @r = split(/$MARCA\(($terminador)$MARCA\)/,$_);
      @r = split(/$MARCA/,$_);
  }
  if   ($r[-1] =~ /^\s*$/s)        {pop(@r);}
#  elsif($r[-1] !~ /^$terminador$/s){push(@r,'');}
  @r;
}

sub cqptokens{
  local $/ = ">";
  while(<>) {
        s/($protect)/savit($1)/xge;
	s#([»\]])#$1 #g;
	s#([«\[])# $1#g;
	s#\"# \" #g;
 	s/(\s*\b\s*|\s+)/\n/g;
	s/(.)\n-\n/$1-/g;
	s/\n+/\n/g;
	s/\n(\.?[ºª])\b/$1/g;
	while ( s#\b([0-9]+)\n([\,.])\n([0-9]+\n)#$1$2$3#g ){};
	s#\n($abrev)\n\.\n#\n$1\.\n#ig;
        s/\n?</\n</;
        $_=loadit($_);
	print;
  }
}

sub savit{
  my $a=shift;
  $savit_p{++$savit_n}=$a ;
  " __MARCA__$savit_n "
}

sub loadit{
  my $a = shift;
  $a =~ s/ ?__MARCA__(\d+) ?/$savit_p{$1}/g;
  $savit_n = 0;
  $a;
}

1;

__END__


$lm='[a-záéíóúâêôàãõçüöñ]';                      # letra minuscula
$lM='[A-ZÁÉÍÓÚÂÊÔÀÃÕÇÜÖÑ]';                      # letra Maiuscula
$l1='[A-ZÁÉÍÓÚÂÊÔÀÃÕÇÜÖÑa-záéíóúâêôàãõçüöñ0-9]'; # letra e numero
$c1='[^»a-záéíóúâêà,;?!)]';


=head1 NAME

Lingua::PT::pln - Perl extension for simple natural language processing, portuguese language

=head1 SYNOPSIS

  use Lingua::PT::pln;

  printPN(@options);
  printPNstring($textstrint, @options);
  forPN(sub{my ($pn, $contex)=@_;... } ) ;
  forPNstring(sub{my ($pn, $contex)=@_;... } ,$textstring, regsep) ;
  $st = syllabe($phrase);
  $s = accent($phrase);
  $s = wordaccent($word);
  $s = xmlsentences($textstring);
  @s = sentences($textstring);
  oco({num=>1,output=>"file"}, "infile1", "infile2");
  %o = oco("infile1", "infile2");

  perl -MLingua::PT::pln -e cqptokens file* > out

=head1 DESCRIPTION

=head2 C<oco( $funref )>

  oco({num=>1,output=>"f"}, f1,f2,...)
  oco({alpha=>1,output=>"f"}, f1,f2,...)
  %oc=oco( f1,f2,...)

=head2 C<forPN( $funref )>

Substitutes all C<propername> by C<funref(propername)> in STDIN and sends
output to STDOUT

=head2 C<forPNstring( $funref, "textstring" [, regSeparator] )>

Substitutes all C<propername> by C<funref(propername)> in the text string.

=head2 C<syllabe( $phrase )>

Returns the phrase with the syllabes separated by "|"

=head2 C<accent( $phrase )>

Returns the phrase with the syllabes separated by "|" and accents marked with
the charater ".

=head2 C<cqptokens()>

cpqtokens - encodes a text from STDIN for CQP (one token per line)

=head1 AUTHOR

José João Almeida (jj@di.uminho.pt)

Paulo Rocha (paulo.rocha@alfa.di.uminho.pt)

thanks to

  Diana Santos

=head1 SEE ALSO

perl(1).

cqp(1).

=cut
