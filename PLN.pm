package Lingua::PT::PLN;

#
# AAAACKK!
# use strict;
#
# use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

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
   tokenize

   oco
);
$VERSION = '0.05';

# printPN  - extrai os nomes próprios dum texto.
#   -comp    junta certos nomes: Fermat + Pierre de Fermat = (Pierre de) Fermat
#   -prof
#   -e       "Sebastiao e Silva" "e" como pertencente a PN
#   -em     "em Famalicão" como pertencente a PN
use locale;

my ($conso, $vogal, $np1, $np, @stopw , %vazia , $prof, $adje, $em);
BEGIN{

$conso='[bcdfghjklmñnpqrstvwyxzç]';
$vogal='[áéíóúôâêãõàaeiou]';

$np1=qr{(?:(?:[A-ZÉÚÓÁÂ][.])+|[sS]r[.]|[dD]r[.]|St[oa]?[.]|[A-ZÉÚÓÁÂ]\w+(?:[\'\-]\w+)*)};

if ($e){ $np= qr{$np1(?:\s+(?:d[eao]s?\s+|e\s+)?$np1)*};}
else   { $np= qr{$np1(?:\s+(?:d[eao]s?\s+)?$np1)*};}

@stopw= qw{
no com se em segundo a o os as na nos nas do das dos da tanto
para de desde mas quando esta sem nem só apenas mesmo até uma uns um
pela por pelo pelas pelos depois ao sobre como umas já enquanto aos
também amanhã ontem embora essa nesse olhe hoje não eu ele eles
primeiro simplesmente era foi é será são seja nosso nossa nossos nossas
chama-se chamam-se subtitui resta diz salvo disse diz vamos entra entram
aqui começou lá seu vinham passou quanto sou vi onde este então temos
num aquele tivemos
};


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

sub oco{  ### {from => (file|string), num => 1, alpha => 1, output=> file}
  my %opt = (from => 'file');
  if(ref($_[0]) eq "HASH"){ %opt = (%opt , %{shift(@_)});}
  local $\ = "\n";           # set output record separator
  my $P="(?:[,;:?!]|[.]+|[-]+)";         # pontuacao a contar
  my $A="[A-ZñÑa-záàãâçéèêíóòõôúùûÁÀÃÂÇÉÈÊÍÓÒÕÔÚÙÛ]";
  my $I="[ \"(){}+*=<>\250\256\257\277\253\273]"; # car. a  ignorar
  my %oco=();

  if($opt{from} eq 'string'){
    my (@str) = (@_);
    for(@str){
        for (/($A+(?:['-]$A+)*|$P)/g){ $oco{$_}++;}
    }
  }
  else {
    my (@file) = (@_);
    for(@file){
      open(F,"< $_") or die("cant open $_");
      while (<F>) {
        for (/($A+(?:['-]$A+)*|$P)/g){ $oco{$_}++;}
      }
      close F;
    }
  }

  if($opt{num}){ # imprime por ordem de quantidade de ocorrencias
    if(defined $opt{output}){ open(SORT,"| sort -nr > $opt{output}");}
    else                   { open(SORT,"| sort -nr");}
    for $i (keys %oco) {print SORT "$oco{$i} $i"}
    close SORT;} 
  elsif($opt{alpha}){ # imprime ordenadamente
    if(defined $opt{output}){ open(SORT ,"> $opt{output}");
			     for $i (sort keys %oco ) {print SORT  "$i $oco{$i}";}}
    else { for $i (sort keys %oco ) {print  "$i $oco{$i}";}} }
  else {return (%oco)}
}

sub forPN{ ## opt:  in=> inputfile(sdtin), out => file(stdout)
  my %opt = (sep => "", t => "normal" );
  if(ref($_[0]) eq "HASH"){ %opt = (%opt , %{shift(@_)});}
  my $f=shift;
  my $m="\x01";
  my $f1;
  my $old;
  my $F1 ;
  local $/ = $opt{sep};           # input record separator=1 or more empty lines

  if(defined $opt{in} ){
     open($F1,"$opt{in}") or die("cant open $opt{in}\n"); }
  else{
     $F1=*STDIN; }

  if(defined $opt{out}){
     open(F,">$opt{out}") or die("cant create $opt{out}\n");
     $old = select(F);
  }

  die("invalid parameter") unless (ref($f) eq "CODE");
  if($opt{t} eq "double") {
       $f1=shift;
       die("invalid parameter ". ref($f1) ) unless (ref($f1) eq "CODE");
  }
  while (<$F1>) {
    $ctx=$_;
    if($opt{t} eq "double") {
       s{($np)}{$m($1$m)}g;
       s{(^\s*|[-]\s+|[.!?]\s*)$m\(($np)$m\)}{ $1 . &{$f1}($2,$ctx) }ge;
       s{$m\(($np)$m\)}{                            &{$f }($1,$ctx) }ge;
    }
    else { 
       s{(\w+\s+|[«»,:()'`"]\s*)($np)}{$1 . &{$f }($2,$ctx) }ge;
    }
    print;
  }
  close($F1) if $opt{in};
  if(defined $opt{out}){
     select($old);
     close(F);
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
  my %opt = ();
  if(ref($text) eq "HASH")    { %opt = %$text        ; $text = shift; }
  elsif(ref($text) eq "ARRAY"){ @opt{@$text} = @$text; $text = shift; }

  my (%profissao,%names,%namesduv);

  for($text){
    chop;
    s/\n/ /g;
    for (m/[.?!:;"]\s+($np1\s+$np)/gxs)     { $namesduv{$_}++;}
    for (m![)>(]\s*($np1\s+$np)!gxs)       { $namesduv{$_}++;}
    for (m/(?:[\w«»,]\s+)($np)/gxs)         { $names{$_}++;}
    if ($opt{em}) { for (/$em\s+($npxs)/g) { $gnames{$_}++;}}
    if ($opt{prof}) {
      while(/\b($prof)\s+(?:(?:$sep1)\s+)?($np)/g)   {$profissao{$2}=$1;}
      while(/(?:[\w«»,]\s+|[(])($np),\s*(?:(?:$sep2)\s+)?($prof)/g)
	{$profissao{$1}=$2;}
    }
  }

  # tratamento dos nomes "duvidosos" = Nome prop no inicio duma frase
  #

  for (keys %namesduv){
    if(/^(\w+)/ && $vazia{lc($1)} )   #exemplo "Como Jose Manuel"
      { s/^\w+\s*//;                  # retira-se a 1.a palavra
	$names{$_}++;}
    else
      { $names{$_}++;}
  }

  for (keys %names){
    if(/^(\w+)/ && $vazia{lc($1)} )   #exemplo "Como Jose Manuel"
      { my $ant = $_;
        s/^\w+\s*//;                  # retira-se a 1.a palavra
        $names{$_}+=$names{$ant};
        delete $names{$ant};}
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
    for (/[)>(]\s*($np1\s+$np)/g)       { $namesduv{$_}++;}
    for (/(?:[\w«»,]\s+)($np)/g)         { $names{$_}++;}
    if ($opt{em}) { for (/$em\s+($np)/g) { $gnames{$_}++;}}
    if ($opt{prof}) {
       while(/\b($prof)\s+(?:(?:$sep1)\s+)?($np)/g)   {$profissao{$2}=$1;}
       while(/(?:[\w«»,]\s+|[(])($np),\s*(?:(?:$sep2)\s+)?($prof)/g)
            {$profissao{$1}=$2;}
    }
  }

  # tratamento dos nomes "duvidosos" = Nome prop no inicio duma frase
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
    for (/[)>(]\s*($np1\s+$np)/g)       { $namesduv{$_}++;}
    for (/(?:[\w«»,]\s+)($np)/g)         { $names{$_}++;}
    if ($opt{em}) { for (/$em\s+($np)/g) { $gnames{$_}++;}}
    if ($opt{prof}) {
       while(/\b($prof)\s+(?:(?:$sep1)\s+)?($np)/g)   {$profissao{$2}=$1;}
       while(/(?:[\w«»,]\s+|[(])($np),\s*(?:(?:$sep2)\s+)?($prof)/g)
	 {$profissao{$1}=$2;}
     }
  }

  # tratamento dos nomes "duvidosos" = Nome prop no inicio duma frase
  #

  for (keys %namesduv){
    if(/^(\w+)/ && $vazia{lc($1)} )   #exemplo "Como Jose Manuel"
      {s/^\w+\s*//;                  # retira-se a 1.a palavra
       $names{$_}++;}
    else
      { $names{$_}++;}
  }

  ##### Não sei bem se isto serve...

  for (keys %names){
    if(/^(\w+)/ && $vazia{lc($1)} )   #exemplo "Como Jose Manuel"
      { my $ant = $_;
        s/^\w+\s*//;                  # retira-se a 1.a palavra
        $names{$_}+=$names{$ant};
        delete $names{$ant};}
  }

  if($opt{oco}){
    for (sort {$names{$b} <=> $names{$a}} keys %names )
      {printf("%6d - %s\n",$names{$_}, $_ );}
  }
  else
    {
      if($opt{comp}){my @l = sort compara keys %names;
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
    s/(\w*[áéíóúôâêãõ])/"$1/        or  # word with an accent character
      s/(\w*)([ua])(ir)$/$1$2|"$3/  or  # word ending with air uir
	s/(\w*([zlr]|[iu]s?))$/"$1/ or  # word ending with z l r i u is us
	  s/(\w+\|\w+)$/"$1/        or  # accent in 2 syllabe frm the end
	    s/(\w)/"$1/;                # accent in the only syllabe

    s/"(($conso)*($vogal|[yw]))/$1:/ ;
    s/"qu:($vogal|[yw])/qu$1:/ ;
    s/:([áéíóúôâêãõ])/$1:/  ;
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
	   2 => "eaoáéíóúôâêûàãõäëïöü",
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

my $terminador='([.?!;:]+[»]?|<[pP]\b.*?>|<br>)';

my $protect = '
       \#n\d+
    |  \w+\'\w+
    |  [\w_.-]+ \@ [\w_.-]+                      # emails
    |  \w+\.[ºª]                                 # ordinals
    |  <[^>]*>                                   # marcup XML SGML
    |  \d+(?:\.\d+)+                             # numbers
    |  \d+\:\d+                                  # the time
    |  ((https?|ftp|gopher)://|www)[\w_./~-]+    # urls
    |  \w+(-\w+)+                                # dá-lo-à
';

my $abrev = join '|', qw( srt?a? dra? [A-Z] etc exa? jr profs? arq av estr?
			  et al vol no eng tv lgo pr Oliv ig mrs? min rep );

sub setabrev{
  $abrev = join '|' , @_;
}

sub xmlsentences{   ## st=> "s"
  my %opt=(st => "s") ;
  if(ref($_[0]) eq "HASH"){ %opt = (%opt , %{shift(@_)});}
  my $par=shift;
  join("\n",map {"<$opt{st}>$_</$opt{st}>"} (sentences($par)));
}

sub sentences{
  my $MARCA="\0x01";
  my $par=shift;
  for($par){
    s#($protect)#          savit($1)#xge;
    s#\b(($abrev)\.)#      savit($1)#ige;
    s#($terminador)#$1$MARCA#g;
    $_=loadit($_);
    @r = split(/$MARCA/,$_);
  }
  if (@r && $r[-1] =~ /^\s*$/s)        {pop(@r);}
  @r;
}

sub tokenize{
  my $conf = { rs => "\n" };
  my $text = shift;
  if (ref($text) eq "HASH") {
    $conf = { %$conf, %$text };
    $text = shift;
  }
  my $result = "";
  local $/ = ">";
  my %tag=();
  my ($a,$b);
  for ($text) {
    if(/<(\w+)(.*?)>/)
      { ($a, $b) = ($1,$2);
	if ($b =~ /=/ )  { $tag{'v'}{$a}++ }
	else             { $tag{'s'}{$a}++ }
      }
    s/<\?xml.*?\?>//s;
    s/($protect)/savit($1)/xge;
    s/([»\]])/$1 /g;
    s#([«\[])# $1#g;
    s#\"# \" #g;
    s/(\s*\b\s*|\s+)/\n/g;
    s/(.)\n-\n/$1-/g;
	s/\n+/\n/g;
	s/\n(\.?[ºª])\b/$1/g;
	while ( s#\b([0-9]+)\n([\,.])\n([0-9]+\n)#$1$2$3#g ){};
	s#\n($abrev)\n\.\n#\n$1\.\n#ig;
        s/\n*</\n</;
        $_=loadit($_);
        s/(\s*\n)+$/\n/;
        s/^(\s*\n)+//;
        $result.=$_;
  }

  $result =~ s/\n/$conf->{rs}/g;
  $result;
}

sub cqptokens{        ## 
  my %opt = ();
  if(ref($_[0]) eq "HASH"){ %opt = (%opt , %{shift(@_)});}
  my $file = shift || "-";

  local $/ = ">";
  my %tag=();
  my ($a,$b);
  open(F,"$file");
  while(<F>) {
        if(/<(\w+)(.*?)>/){ ($a, $b) = ($1,$2);
             if ($b =~ /=/ )  { $tag{v}{$a}++ }
             else             { $tag{s}{$a}++ }
        }
        s/<\?xml.*?\?>//s;
        s/($protect)/savit($1)/xge;
	s#([»\]])#$1 #g;
	s#([«\[])# $1#g;
	s#\"# \" #g;
 	s/(\s*\b\s*|\s+)/\n/g;
	#s/(.)\n-\n/$1-/g;
	s/\n+/\n/g;
	s/\n(\.?[ºª])\b/$1/g;
	while ( s#\b([0-9]+)\n([\,.])\n([0-9]+\n)#$1$2$3#g ){};
	s#\n($abrev)\n\.\n#\n$1\.\n#ig;
        s/\n*</\n</;
        $_=loadit($_);
        s/(\s*\n)+$/\n/;
        s/^(\s*\n)+//;
	print;
  }
  +{%tag}
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

Lingua::PT::PLN - Perl extension for simple natural language processing, portuguese language

=head1 SYNOPSIS

  use Lingua::PT::PLN;

  printPN(@options);
  printPNstring({ %options... } ,$textstrint);
  printPNstring([ @options... ] ,$textstrint);

  forPN( sub{my ($pn, $contex)=@_;... } ) ;
  forPN( {p=>"double"}, sub{my ($pn, $contex)=@_;... }, sub{...} ) ;

  forPNstring(sub{my ($pn, $contex)=@_;... } ,$textstring, regsep) ;

  $st = syllabe($phrase);
  $s = accent($phrase);
  $s = wordaccent($word);

  $s = xmlsentences($textstring);
  $s = xmlsentences({st=>"frase"},$textstring);
  @s = sentences($textstring);

  %o = oco("infile1", "infile2");
       oco({num=>1,output=>"file"}, "infile1", "infile2");
  %o = oco({from=>"string"},"string1");

  perl -MLingua::PT::PLN -e 'cqptokens("file")' > out

=head1 DESCRIPTION

=head2 C<oco([options,], file*)>

Option C<num=1> means sorted by number of ocorrences.

Option C<alpha=1> means sorted lexicografically.

Option C<output=f> means write output to f

Option C<from="string"> means that input is a string instead of a file

  oco({num=>1,output=>"f"}, f1,f2,...)
  oco({alpha=>1,output=>"f"}, f1,f2,...)
  %oc=oco( f1,f2,...)
  %oc=oco( {from=>"string"},"text in a string")

=head2 C<forPN( $funref )>

Substitutes all C<propername> by C<funref(propername)> in STDIN and sends
output to STDOUT

Opcionally you can pass C<{t => "full"}> as first parameter to obtain names
after "." 

   forPN({in=> inputfile(sdtin), out => file(stdout)}, sub{...})
   forPN({sep=>"\n", t=>"normal"}, sub{...})
   forPN({sep=>'', t=>"double"}, sub{...}, sub{...})



=head2 C<forPNstring( $funref, "textstring" [, regSeparator] )>

Substitutes all C<propername> by C<funref(propername)> in the text string.

=head2 C<printPNstring(options)>

   printPN("oco")

   printPNstring("oco")

=head2 C<syllabe( $phrase )>

Returns the phrase with the syllabes separated by "|"

=head2 C<accent( $phrase )>

Returns the phrase with the syllabes separated by "|" and accents marked with
the charater ".

=head2 C<cqptokens()>

cpqtokens - encodes a text from STDIN for CQP (one token per line)

=head2 C<sentences()>

sentences - ....

=head2 C<xmlsentences()>

xmlsentences - ....

By default, sentences are marked with "s". To change this use C<st> optional
parameter. Example:

  xmlsentences({st=> "tag"}, text) 

to mark sentences with tag "tag".

=head1 AUTHOR

José João Almeida (jj@di.uminho.pt)

Alberto Simões (albie@alfarrabio.di.uminho.pt)

Paulo Rocha (paulo.rocha@di.uminho.pt)

thanks to

  Diana Santos

=head1 SEE ALSO

perl(1).

cqp(1).

=cut
