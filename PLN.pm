package Lingua::PT::PLN;

use strict;
require Exporter;
our @ISA = qw(Exporter AutoLoader);

our @EXPORT = qw(
   getPN printPN printPNstring forPN forPNstring

   syllable accent wordaccent

   xmlsentences sentences

   cqptokens tokenize

   tokeniza tratar_pontuacao_interna protege_atr_estruturais
   recupera_ortografia_certa separa_frases

   oco
);
our $VERSION = '0.07';

# printPN  - extrai os nomes próprios dum texto.
#   -comp    junta certos nomes: Fermat + Pierre de Fermat = (Pierre de) Fermat
#   -prof
#   -e       "Sebastiao e Silva" "e" como pertencente a PN
#   -em     "em Famalicão" como pertencente a PN
use locale;

our ($consoante, $vogal, $np1, $np, @stopw , %vazia , $prof, $adje, $em, $e, $sep1, $sep2, %names, %gnames);


BEGIN{
  $consoante='[bcçdfghjklmñnpqrstvwyxz]';
  $vogal='[áéíóúâêôãõàaeiou]';

  $np1=qr{(?:(?:[A-ZÉÚÓÁÂ][.])+|[sS]r[.]|[dD]r[.]|St[oa]?[.]|[A-ZÉÚÓÁÂ]\w+(?:[\'\-]\w+)*)};

  if ($e) {
    $np= qr{$np1(?:\s+(?:d[eao]s?\s+|e\s+)?$np1)*};
  } else {
    $np= qr{$np1(?:\s+(?:d[eao]s?\s+)?$np1)*};
  }

  @stopw = qw{
              no com se em segundo a o os as na nos nas do das dos da tanto
              para de desde mas quando esta sem nem só apenas mesmo até uma uns um
              pela por pelo pelas pelos depois ao sobre como umas já enquanto aos
              também amanhã ontem embora essa nesse olhe hoje não eu ele eles
              primeiro simplesmente era foi é será são seja nosso nossa nossos nossas
              chama-se chamam-se subtitui resta diz salvo disse diz vamos entra entram
              aqui começou lá seu vinham passou quanto sou vi onde este então temos
              num aquele tivemos
             };


  $prof = join("|", qw{
                       astrólogo astrónomo advogado actor
                       baterista
                       cantor compositor
                       dramaturgo
                       engenheiro escritor
                       filósofo flautista físico
                       investigador
                       jogador
                       matemático médico ministro músico
                       pianista poeta professor
                       químico
                       teólogo
                      });

  $adje = join("|", qw{
                       português francês inglês espanhol
                       internacional bracarence minhoto
                      });

  $sep1 = join("|", qw{chamado "conhecido como"});

  $sep2 = join("|", qw{brilhante conhecido reputado popular});

  @vazia{@stopw} = (@stopw); # para ser mais facil ver se uma pal é stopword
  $em = '\b(?:[Ee]m|[nN][oa]s?)';
}



sub oco {
  ### {from => (file|string), num => 1, alpha => 1, output=> file}

  my %opt = (from => 'file');
  %opt = (%opt , %{shift(@_)}) if ref($_[0]) eq "HASH";

  local $\ = "\n";                    # set output record separator

  my $P="(?:[,;:?!]|[.]+|[-]+)";      # pontuacao a contar
  my $A="[A-ZñÑa-záàãâçéèêíóòõôúùûÁÀÃÂÇÉÈÊÍÓÒÕÔÚÙÛ]";
  my $I="[ \"(){}+*=<>\250\256\257\277\253\273]"; # car. a  ignorar
  my %oco=();

  if ($opt{from} eq 'string') {
    my (@str) = (@_);
    for (@str) {
      for (/($A+(?:['-]$A+)*|$P)/g) { $oco{$_}++; }
    }
  } else {
    my (@file) = (@_);
    for(@file) {
      open F,"< $_" or die "cant open $_: $!";
      while (<F>) {
        for (/($A+(?:['-]$A+)*|$P)/g) { $oco{$_}++; }
      }
      close F;
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

  } elsif ($opt{alpha}) { # imprime ordenadamente

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

sub forPN{
  ## opt:  in=> inputfile(sdtin), out => file(stdout)
  my %opt = (sep => "", t => "normal" );

  %opt = (%opt , %{shift(@_)}) if ref($_[0]) eq "HASH";

  my $f=shift;
  my $m="\x01";
  my $f1;
  my $old;
  my $F1 ;

  local $/ = $opt{sep};  # input record separator=1 or more empty lines

  if (defined $opt{in}) {
    open $F1, "$opt{in}" or die "cant open $opt{in}\n";
  } else {
    $F1=*STDIN;
  }

  if (defined $opt{out}) {
    open F, ">$opt{out}" or die "cant create $opt{out}\n";
    $old = select(F);
  }

  die "invalid parameter to 'forPN'" unless ref($f) eq "CODE";

  if ($opt{t} eq "double") {
    $f1 = shift;
    die "invalid parameter ". ref($f1) unless ref($f1) eq "CODE";
  }

  while (<$F1>) {
    my $ctx = $_;
    if ($opt{t} eq "double") {

      s{($np)}{$m($1$m)}g;
      s{(^\s*|[-]\s+|[.!?]\s*)$m\(($np)$m\)}{
	my ($aux1,$aux2,$aux3)= ($1,$2, &{$f1}($2,$ctx));
	if   (defined($aux3)){$aux1 . $aux3}
	else                 {$aux1 . tryright($aux2)} }ge;
      s{$m\(($np)$m\)}{   &{$f }($1,$ctx) }ge;

    } else {
      s{(\w+\s+|[\«\»,:()'`"]\s*)($np)}{$1 . &{$f }($2,$ctx) }ge;
    }
    print;
  }
  close $F1 if $opt{in};
  if (defined $opt{out}) {
    select $old;
    close F;
  }
}

sub tryright{
  my $a = shift;
  return $a unless $a =~ /(\w+)/;
  my $m = "\x01";
  my ($w,$r) = ($1,$');
  $r =~ s{($np)}{$m($1$m)}g;
  return "$w$r";
}


sub forPNstring {
  my $f = shift;
  die "invalid parameter to 'forPNstring': function expected" unless ref($f) eq "CODE";
  my $text = shift;
  my $sep = shift || "\n";
  my $r = '';
  for (split(/$sep/,$text)) {
    my $ctx = $_;
    s/(\w+\s+|[\«\»,()'`i"]\s*)($np)/$1 . &{$f}($2,$ctx)/ge       ;
    $r .= "$_$sep";
  }
  return $r;
}

sub printPNstring{
  my $text = shift;
  my %opt = ();

  if   (ref($text) eq "HASH") { %opt = %$text        ; $text = shift; }
  elsif(ref($text) eq "ARRAY"){ @opt{@$text} = @$text; $text = shift; }

  my (%profissao, %names, %namesduv);

  for ($text) {
    chop;
    s/\n/ /g;
    for (m/[.?!:;"]\s+($np1\s+$np)/gxs)  { $namesduv{$_}++ }
    for (m![)>(]\s*($np1\s+$np)!gxs)     { $namesduv{$_}++ }
    for (m/(?:[\w\«\»,]\s+)($np)/gxs)    { $names{$_}++ }
    if ($opt{em}) {
      for (/$em\s+($np)/g) { $gnames{$_}++ }
    }
    if ($opt{prof}) {
      while(/\b($prof)\s+(?:(?:$sep1)\s+)?($np)/g)
	{ $profissao{$2} = $1 }
      while(/(?:[\w\«\»,]\s+|[(])($np),\s*(?:(?:$sep2)\s+)?($prof)/g)
	{ $profissao{$1} = $2 }
    }
  }

  # tratamento dos nomes "duvidosos" = Nome prop no inicio duma frase
  #

  for (keys %namesduv) {
    if (/^(\w+)/ && $vazia{lc($1)}) { #exemplo "Como Jose Manuel"
      s/^\w+\s*//;                    # retira-se a 1.a palavra
      $names{$_}++
    } else { 
      $names{$_}++
    }
  }

  for (keys %names) {
    if (/^(\w+)/ && $vazia{lc($1)}) {  #exemplo "Como Jose Manuel"
      my $ant = $_;
      s/^\w+\s*//;                     # retira-se a 1.a palavra
      $names{$_} += $names{$ant};
      delete $names{$ant}
    }
  }

  if ($opt{oco}) {
    for (sort {$names{$b} <=> $names{$a}} keys %names ) {
      printf("%60s - %d\n", $_ ,$names{$_});
    }
  } else {
    if ($opt{comp}) {
      my @l = sort compara keys %names;
      compacta(@l)
    } else {
      for (sort compara keys %names ) {
	printf("%60s - %d\n", $_ ,$names{$_});
      }
    }
    if ($opt{prof}) {
      print "\nProfissões\n";
      for (keys %profissao) {
	print "$_ -- $profissao{$_}"
      }
    }
    if ($opt{em}) {
      print "\nGeograficos\n";
      for (sort compara keys %gnames ) {
	printf("%60s - %d\n", $_ ,$gnames{$_})
      }
    }
  }
}

sub getPN {
  local $/ = "";           # input record separator=1 or more empty lines

  my %opt;
  @opt{@_} = @_;
  my (%profissao, %names, %namesduv);

  while (<>) {
    chop;
    s/\n/ /g;
    for (/[.?!:;"]\s+($np1\s+$np)/g)     { $namesduv{$_}++;}
    for (/[)>(]\s*($np1\s+$np)/g)        { $namesduv{$_}++;}
    for (/(?:[\w\«\»,]\s+)($np)/g)       { $names{$_}++;}
    if ($opt{em}) {
      for (/$em\s+($np)/g) { $gnames{$_}++;}}
    if ($opt{prof}) {
       while(/\b($prof)\s+(?:(?:$sep1)\s+)?($np)/g)
	 { $profissao{$2} = $1 }
       while(/(?:[\w\«\»,]\s+|[(])($np),\s*(?:(?:$sep2)\s+)?($prof)/g)
	 { $profissao{$1} = $2 }
     }
  }

  # tratamento dos nomes "duvidosos" = Nome prop no inicio duma frase
  #

  for (keys %namesduv) {
    if(/^(\w+)/ && $vazia{lc($1)}) {  # exemplo "Como Jose Manuel"
      s/^\w+\s*//;                    # retira-se a 1.a palavra
      $names{$_}++
    } else {
      $names{$_}++
    }
  }
  return (%names)
}

sub printPN{
  local $/ = "";           # input record separator=1 or more empty lines

  my %opt;
  @opt{@_} = @_;
  my (%profissao, %names, %namesduv);

  while (<>) {
    chop;
    s/\n/ /g;
    for (/[.?!:;"]\s+($np1\s+$np)/g)     { $namesduv{$_}++ }
    for (/[)>(]\s*($np1\s+$np)/g)        { $namesduv{$_}++ }
    for (/(?:[\w\«\»,]\s+)($np)/g)       { $names{$_}++ }
    if ($opt{em}) {
      for (/$em\s+($np)/g) { $gnames{$_}++ }
    }
    if ($opt{prof}) {
       while(/\b($prof)\s+(?:(?:$sep1)\s+)?($np)/g)
	 { $profissao{$2} = $1 }
       while(/(?:[\w\«\»,]\s+|[(])($np),\s*(?:(?:$sep2)\s+)?($prof)/g)
	 { $profissao{$1} = $2 }
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
  my $p=syllable(shift);
  for ($p){
    s/(\w*[áéíóúôâêãõ])/"$1/        or  # word with an accent character
      s/(\w*)([ua])(ir)$/$1$2|"$3/  or  # word ending with air uir
	s/(\w*([zlr]|[iu]s?))$/"$1/ or  # word ending with z l r i u is us
	  s/(\w+\|\w+)$/"$1/        or  # accent in 2 syllable frm the end
	    s/(\w)/"$1/;                # accent in the only syllable

    s/"(($consoante)*($vogal|[yw]))/$1:/ ;
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

sub syllable{
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
  my $s;
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
    |  [\w_.-]+ \@ [\w_.-]+\w                    # emails
    |  \w+\.[ºª]                                 # ordinals
    |  <[^>]*>                                   # marcup XML SGML
    |  \d+(?:\.\d+)+                             # numbers
    |  \d+\:\d+                                  # the time
    |  ((https?|ftp|gopher)://|www)[\w_./~-]+\w  # urls
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
  my @r;
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

sub tokeniza{
  my $par = shift;

  for ($par) {
    s/([!?]+)/ $1/g;
    s/([.,;\»])/ $1/g;
    s/:([^0-9])/ :$1/g; # separa os dois pontos só se não entre
                        # números 9:30...
    s/([^0-9]):([^\/])/$1 :$2/g; # separa os dois pontos só se não
                                 # entre números e não for http:/...
    s/([\«`])/$1 /g; #
    s/\(([^1-9*])/\( $1/g; # só separa o parêntesis esquerdo quando
                           # não engloba números ou asterisco
    s/([^0-9*%])\)/$1 \)/g; # só separa o parêntesis direito quando
                            # não engloba números ou asterisco ou
                            # percentagem
    s/> *([A-Za-z]) \)/> $1\)/g; # desfaz a separação dos parênteses
                                 # para B)
    s/> *\( ([a-z]) \)/> \($1\)/g; # desfaz a separação dos parênteses
                                   # para (a)
    s/(\( +[A-Z]+[0-9]+)\)/ $1 \)/g; # separação dos parênteses para ( A4 )

    s/\[([^.§])/[ $1/g; # separa o parêntesis recto esquerdo desde que não [..
    s/([^.§])\]/$1 ]/g; # separa o parêntesis recto direito desde que não ..]

    s/([^[])§/$1 §/g; # separa as reticências só se não dentro de [...]

    s/http :/http:/g; # desfaz a separação dos http:

    s/ \"/ \« /g; # separa as aspas anteriores
    s/\" / \» /g;  # separa as aspas posteriores
    s/\"$/ \»/g;   # separa as aspas posteriores mesmo no fim

    # trata dos apóstrofes

    s/([^dDlL])\'([\s\',:.?!])/$1 \'$2/g;  # trata do apóstrofe: só
                                           # separa se for pelica
    s/(\S[dDlL])\'([\s\',:.?!])/$1 \'$2/g; # trata do apóstrofe: só
                                           # separa se for pelica
    s/([A-ZÊÁÉÍÓÚÀÇÔÕÃÂa-zôõçáéíóúâêàã])\'([A-ZÊÁÉÍÓÚÀÇÔÕÃÂa-zôõçáéíóúâêàã])/$1\' $2/; 
    # separa d' do resto da palavra "d'amor"... "dest'época"

    s/(\s[A-Z]+)\' s([\s,:.?!])/$1\'s$2/g; #Para repor PME's

    s/ '([A-Za-zÁÓÚÉÊÀÂÍ])/ ' $1/g; # separa um apóstrofe final usado como inicial
    s/^'([A-Za-zÁÓÚÉÊÀÂÍ])/' $1/g;  # separa um apóstrofe final usado como inicial

    # trata dos (1) ou 1)

    s/([a-záéãó])\(([0-9])/$1 \($2/g; # separa casos como Rocha(1) para Rocha (1)
    s/:([0-9]\))/ : $1/g; # separa casos como dupla finalidade:1)

    # trata dos hífenes
    s/\)\-([A-Z])/\) - $1/g; # separa casos como (Itália)-Juventus para Itália) -
    s/([0-9]\-)([^0-9\s])/$1 $2/g; # separa casos como 1-universidade
  }

  #trata das barras
  #se houver palavras que nao sao todas em maiusculas, separa
  my @barras= ($par=~m%(?:[a-z]+/)+(?:[A-Za-z][a-z]*)%g);
  my $exp_antiga;
  foreach my $exp_com_barras (@barras) {
    if (($exp_com_barras !~ /[a-z]+a\/o$/) and # Ambicioso/a
        ($exp_com_barras !~ /[a-z]+o\/a$/) and # cozinheira/o
        ($exp_com_barras !~ /[a-z]+r\/a$/)) { # desenhador/a
      $exp_antiga=$exp_com_barras;
      $exp_com_barras=~s#/# / #g;
      $par=~s/$exp_antiga/$exp_com_barras/g;
    }
  }

  for ($par) {
    s# e / ou # e/ou #g;
    s#([Kk])m / h#$1m/h#g;
    s# mg / kg# mg/kg#g;
    s#r / c#r/c#g;
    s#m / f#m/f#g;
    s#f / m#f/m#g;
  }
  $par =~ s/\ +/\n/g;
  $par;
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
    if(/<(\w+)(.*?)>/) {
      ($a, $b) = ($1,$2);
      if ($b =~ /=/ )  { $tag{'v'}{$a}++ }
      else             { $tag{'s'}{$a}++ }
    }
    s/<\?xml.*?\?>//s;
    s/($protect)/savit($1)/xge;
    s!([\»\]])!$1 !g;
    s#([\«\[])# $1#g;
    s#\"# \" #g;
    s/(\s*\b\s*|\s+)/\n/g;
    # s/(.)\n-\n/$1-/g;
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
  $result =~ s/\n$//g;
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
    if(/<(\w+)(.*?)>/){
      ($a, $b) = ($1,$2);
      if ($b =~ /=/ )  { $tag{'v'}{$a}++ }
      else             { $tag{'s'}{$a}++ }
    }
    s/<\?xml.*?\?>//s;
    s/($protect)/savit($1)/xge;
    s#([\»\]])#$1 #g;
    s#([\«\[])# $1#g;
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

##--
sub tratar_pontuacao_interna {
  my $par = shift;

  for ($par) {
    s/§/§§/g;         # proteger o §
    s/\.\.\.+/§/g;    # tratar das reticências
    s/\+/\+\+/g;

    # tratar de iniciais seguidas por ponto, eventualmente com
    # parênteses, no fim de uma frase
    s/([A-Z])\. ([A-Z])\.(\s*[])]*\s*)$/$1+ $2+$3 /g;

    # iniciais com espaço no meio...
    s/ a\. C\./ a+C+/g;
    s/ d\. C\./ d+C+/g;

    # tratar dos pontos nas abreviaturas
    s/\.º/º+/g;
    s/º\./+º/g;
    s/\.ª/+ª/g;
    s/ª\./ª+/g;
    #só mudar se não for ambíguo com ponto final
    s/º\. +([^A-ZÀÁÉÍÓÚÂÊ\«])/º+ $1/g;

    # formas de tratamento
    s/Ex\./Ex+/g; # Ex.
    s/ ex\./ ex+/g; # ex.
    s/Exa(s*)\./Exa$1+/g; # Exa., Exas.
    s/ exa(s*)\./ exa$1+/g; # exa., exas
    s/Pe\./Pe+/g;
    s/Dr(a*)\./Dr$1+/g; # Dr., Dra.
    s/ dr(a*)\./ dr$1+/g; # dr., dra.
    s/ drs\./ drs+/g; # drs.
    s/Eng(a*)\./Eng$1+/g; # Eng., Enga.
    s/ eng(a*)\./ eng$1+/g; # eng., enga.
    s/([Ss])r(t*)a\./$1r$2a+/g; # Sra., sra., Srta., srta.
    s/([Ss])r(s*)\./$1r$2+/g; # Sr., sr., Srs., srs.
    s/ arq\./ arq+/g; # arq.
    s/Prof(s*)\./Prof$1+/g; # Prof., Profs.
    s/Profa(s*)\./Profa$1+/g; # Profa., Profas.
    s/ prof(s*)\./ prof$1+/g; # prof., profs.
    s/ profa(s*)\./ profa$1+/g; # profa., profas.
    s/\. Sen\./+ Sen+/g; # senador (vem sempre depois de Av. ou R. ...)
    s/ua Sen\./ua Sen+/g; # senador (depois [Rr]ua ...)
    s/Cel\./Cel+/g; # coronel
    s/ d\. / d+ /g; # d. Luciano

    # partes de nomes (pospostos)
    s/ ([lL])da\./ $1da+/g; # limitada
    s/ cia\./ cia+/g; # companhia
    s/Cia\./Cia+/g; # companhia
    s/Jr\./Jr+/g;

    # moradas
    s/Av\./Av+/g;
    s/ av\./ av+/g;
    s/Est(r*)\./Est$1+/g;
    s/Lg(o*)\./Lg$1+/g;
    s/ lg(o*)\./ lg$1+/g;
    s/T(ra)*v\./T$1v+/g; # Trav., Tv.
    s/([^N])Pq\./$1Pq+/g; # Parque (cuidado com CNPq)
    s/ pq\./ pq+/g; # parque
    s/Jd\./Jd+/g; # jardim
    s/Ft\./Ft+/g; # forte
    s/Cj\./Cj+/g; # conjunto
    s/ ([lc])j\./ $1j+/g; # conjunto ou loja
    #   s/ al\./ al+/g; # alameda tem que ir para depois de et.al...

    s/Tel(e[fm])*\./Tel$1+/g; # Tel., Telef., Telem.
    s/ tel(e[fm])*\./ tel$1+/g; # tel., telef., telem.
    s/Fax\./Fax+/g; # Fax.
    s/ cx\./ cx+/g; # caixa

    # abreviaturas greco-latinas
    s/ a\.C\./ a+C+/g;
    s/ a\.c\./ a+c+/g;
    s/ d\.C\./ d+C+/g;
    s/ d\.c\./ d+c+/g;
    s/ ca\./ ca+/g;
    s/etc\.([.,;])/etc+$1/g;
    s/etc\.\)([.,;])/etc+)$1/g;
    s/etc\. --( *[a-záéíóúâêà,])/etc+ --$1/g;
    s/etc\.(\)*) ([^A-ZÀÁÉÍÓÂÊ<])/etc+$1 $2/g;
    s/ et\. *al\./ et+al+/g;
    s/ al\./ al+/g; # alameda 
    s/ q\.b\./ q+b+/g;
    s/ i\.e\./ i+e+/g;
    s/ibid\./ibid+/g;
    s/ id\./ id+/g; # se calhar é preciso ver se não vem sempre precedido de um (
    s/op\.( )*cit\./op+$1cit+/g;
    s/P\.S\./P+S+/g;

    # unidades de medida
    s/([0-9][hm])\. ([^A-ZÀÁÉÍÓÚÂÊ])/$1+ $2/g; # 19h., 24m.
    s/([0-9][km]m)\. ([^A-ZÀÁÉÍÓÚÂÊ])/$1+ $2/g; # 20km., 24mm.
    s/([0-9]kms)\. ([^A-ZÀÁÉÍÓÚÂÊ])/$1+ $2/g; # kms. !!
    s/(\bm)\./$1+/g; # metros no MINHO

    # outros
    s/\(([Oo]rgs*)\.\)/($1+)/g; # (orgs.)
    s/\(([Ee]ds*)\.\)/($1+)/g; # (eds.)
    s/séc\./séc+/g;
    s/pág(s*)\./pág$1+/g;
    s/pg\./pg+/g;
    s/pag\./pag+/g;
    s/ ed\./ ed+/g;
    s/Ed\./Ed+/g;
    s/ sáb\./ sáb+/g;
    s/ dom\./ dom+/g;
    s/ id\./ id+/g;
    s/ min\./ min+/g;
    s/ n\.o(s*) / n+o$1 /g; # abreviatura de numero no MLCC-DEB
    s/ ([Nn])o\.(s*)\s*([0-9])/ $1o+$2 $3/g; # abreviatura de numero no., No.
    s/ n\.(s*)\s*([0-9])/ n+$1 $2/g; # abreviatura de numero n. no ANCIB
    s/ num\. *([0-9])/ num+ $1/g; # abreviatura de numero num. no ANCIB
    s/ c\. ([0-9])/ c+ $1/g; # c. 1830
    s/ p\.ex\./ p+ex+/g;
    s/ p\./ p+/g;
    s/ pp\./ pp+/g;
    s/ art(s*)\./ art$1+/g;
    s/Min\./Min+/g;
    s/Inst\./Inst+/g;
    s/vol(s*)\./vol$1+ /g;
    s/ v\. *([0-9])/ v+ $1/g; # abreviatura de volume no ANCIB
    s/\(v\. *([0-9])/\(v+ $1/g; # abreviatura de volume no ANCIB
    s/^v\. *([0-9])/v+ $1/g; # abreviatura de volume no ANCIB
    s/Obs\./Obs+/g;

    # Abreviaturas de meses
    s/(\W)jan\./$1jan+/g;
    s/\Wfev\./$1fev+/g;
    s/(\/\s*)mar\.(\s*[0-9\/])/$1mar+$2/g; # a palavra "mar"
    s/(\W)mar\.(\s*[0-9]+)/$1mar\+$2/g;
    s/(\W)abr\./$1abr+/g;
    s/(\W)mai\./$1mai+/g;
    s/(\W)jun\./$1jun+/g;
    s/(\W)jul\./$1jul+/g;
    s/(\/\s*)ago\.(\s*[0-9\/])/$1ago+$2/g; # a palavra inglesa "ago"
    s/ ago\.(\s*[0-9\/])/ ago+$1/g; # a palavra inglesa "ago./"
    s/(\W)set\.(\s*[0-9\/])/$1set+$2/g; # a palavra inglesa "set"
    s/([ \/])out\.(\s*[0-9\/])/$1out+$2/g; # a palavra inglesa "out"
    s/(\W)nov\./$1nov+/g;
    s/(\/\s*)dez\.(\s*[0-9\/])/$1dez+$2/g; # a palavra "dez"
    s/(\/\s*)dez\./$1dez+/g; # a palavra "/dez."

    # Abreviaturas inglesas
    s/Bros\./Bros+/g;
    s/Co\. /Co+ /g;
    s/Co\.$/Co+/g;
    s/Com\. /Com+ /g;
    s/Com\.$/Com+/g;
    s/Corp\. /Corp+ /g;
    s/Inc\. /Inc+ /g;
    s/Ltd\. /Ltd+ /g;
    s/([Mm])r(s*)\. /$1r$2+ /g;
    s/Ph\.D\./Ph+D+/g;
    s/St\. /St+ /g;
    s/ st\. / st+ /g;

    # Abreviaturas inventadas
    s/jj/Jose Joao/g;

    # Abreviaturas francesas
    s/Mme\./Mme+/g;

    # Abreviaturas especiais do Diário do Minho
    s/ habilit\./ habilit+/g;
    s/Hab\./Hab+/g;
    s/Mot\./Mot+/g;
    s/\-Ang\./-Ang+/g;
    s/(\bSp)\./$1+/g; # Sporting
    s/(\bUn)\./$1+/g; # Universidade

    # Abreviaturas especiais do Folha
    s/([^'])Or\./$1Or+/g; # alemanha Oriental, evitar d'Or
    s/Oc\./Oc+/g; # alemanha Ocidental
  }

  # tratar dos conjuntos de iniciais
  my @siglas_iniciais=($par=~/^(?:[A-Z]\. *)+[A-Z]\./);
  my @siglas_finais=($par=~/(?:[A-Z]\. *)+[A-Z]\.$/);
  my @siglas=($par=~m#(?:[A-Z]\. *)+(?:[A-Z]\.)(?=[]\)\s,;:!?/])#g); #trata de conjuntos de iniciais
  push (@siglas, @siglas_iniciais);
  push (@siglas, @siglas_finais);
  my $sigla_antiga;
  foreach my $sigla (@siglas) {
    $sigla_antiga = $sigla;
    $sigla=~s/\./+/g;
    $sigla_antiga=~s/\./\\\./g;
    #	print "SIGLA antes: $sigla, $sigla_antiga\n";
    $par=~s/$sigla_antiga/$sigla/g;
    #	print "SIGLA: $sigla\n";
  }

  # tratar de pares de iniciais ligadas por hífen (à francesa: A.-F.)
  for ($par) {
    s/ ([A-Z])\.\-([A-Z])\. / $1+-$2+ /g;
    s/ ([A-Z])\. / $1+ /g; # tratar de iniciais (únicas?) seguidas por ponto
    s/^([A-Z])\. /$1+ /g; # tratar de iniciais seguidas por ponto
    s/([("\«])([A-Z])\. /$1$2+ /g; # tratar de iniciais seguidas por
                                   # ponto antes de aspas "D. João VI:
                                   # Um Rei Aclamado"
  }

  # Tratar dos URLs (e também dos endereços de email)
  # email= url@url...
  # aceito endereços seguidos de /hgdha/hdga.html
  #  seguidos de /~hgdha/hdga.html
  #    @urls=($par=~/(?:[a-z][a-z0-9-]*\.)+(?:[a-z]+)(?:\/~*[a-z0-9-]+)*?(?:\/~*[a-z0-9][a-z0-9.-]+)*(?:\/[a-z.]+\?[a-z]+=[a-z0-9-]+(?:\&[a-z]+=[a-z0-9-]+)*)*/gi);

  my @urls=($par=~/(?:[a-z][a-z0-9-]*\.)+(?:[a-z]+)(?:\/~*[a-z0-9][a-z0-9.-]+)*(?:\?[a-z]+=[a-z0-9-]+(?:\&[a-z]+=[a-z0-9-]+)*)*/gi);
  my $url_antigo;
  foreach my $url (@urls) {
    $url_antigo=$url;
    $url_antigo=~s/\./\\./g; # para impedir a substituição de P.o em vez de P\.o
    $url_antigo=~s/\?/\\?/g;
    $url=~s/\./+/g;
    $url=~s/\+$/./; # Se o último ponto está mesmo no fim, não faz parte do URL
    $url=~s/\//\/\/\/\//g; #põe quatro ////
    $par=~s/$url_antigo/$url/;
    #	print "URL: $url\n";
  }
  #    print "Depois de tratar dos URLs: $par\n";

  for ($par) {
    s/\. *,/+,/g; # de qualquer maneira, se for um ponto seguido de uma vírgula, é abreviatura...
    s/\. *\./+./g; # de qualquer maneira, se for um ponto seguido de outro ponto, é abreviatura...

    # tratamento de numerais

    s/([0-9]+)\.([0-9]+)\.([0-9]+)/$1_$2_$3/g;
    s/([0-9]+)\.([0-9]+)/$1_$2/g;

    # tratamento de numerais cardinais
    s/^([0-9]+)\. /$1+ /g;  # tratar dos números com ponto no início da frase
    s/([0-9]+)\. ([a-záéíóúâêà])/$1+ $2/g;  # tratar dos números com ponto antes de minúsculas

    # tratamento de numerais ordinais acabados em .o
    s/([0-9]+)\.([oa]s*) /$1+$2 /g;
    # ou expressos como 9a. 
    s/([0-9]+)([oa]s*)\. /$1$2+ /g;

    # tratar numeracao decimal em portugues
    s/([0-9]),([0-9])/$1#$2/g; 

    # tratar indicação de horas
    #   esta é tratada na tokenização - não separando 9:20 em 9 :20
  }
  return $par;
}
##--

sub recupera_ortografia_certa {
  # os sinais literais de + são codificados como "++" para evitar
  # transformação no ponto, que é o significado do "+"

  my $par = shift;

  for ($par) {
    s/([^+])\+(?!\+)/$1./g; # um + não seguido por +
    s/\+\+/+/g;
    s/([^§(])§(?!§)\)/$1... \)/g; # porque se juntou no separa_frases
                                  # So nao se faz se for (...) ...
    s/([^§])§(?!§)/$1.../g; # um § não seguido por §
    s/§§/§/g;
    s/^§/.../g; # se as reticências começam a frase
    #    $par=~s/§/.../g;
    s/_/./g;
    s/#/,/g;
    s#////#/#g; #passa 4 para 1
    s/([?!])\-/$1 \-/g; # porque se juntou no separa_frases
    s/([?!])\)/$1 \)/g; # porque se juntou no separa_frases
  }
  $par;
}


sub separa_frases {
  my $par = shift;

  $par = tratar_pontuacao_interna($par);

  # primeiro junto os ) e os -- ao caracter anterior de pontuação
  for ($par) {
    s/([?!.])\s+\)/$1\)/; # pôr  "ola? )" para "ola?)"
    s/([?!.])\s+\-/$1-/;  # pôr  "ola? --" para "ola?--"
    s/§\s+\-/$1-/;        # pôr  "ola§ --" para "ola§--"


    # separar esta pontuação, apenas se não for dentro de aspas, ou
    # seguida por vírgulas ou parênteses o a-z estáo lá para não
    # separar /asp?id=por ...
    s/([?!]+)([^-»,§?!)"a-z])/$1.$2/g;
    # Deixa-se o travessão para depois


    # separar as reticências entre parênteses apenas se forem seguidas de nova
    # frase, e se não começarem uma frase elas próprias
    s/([\w?!])§([»"]*\)) *([A-ZÁÉÍÓÚÀ])/$1§$2.$3/g;


    # separar os pontos antes de parênteses se forem seguidos de nova frase
    s/([\w])\.([)]) *([A-ZÁÉÍÓÚÀ])/$1 + $2.$3/g;
    # separar os pontos ? e ! antes de parênteses se forem seguidos de
    # nova frase, possivelmente tb iniciada por abre parênteses ou
    # travessão
    s/(\w[?!]+)([)]) *((?:\(|\-\- )*[A-ZÁÉÍÓÚÀ])/$1 $2.$3/g;

    # separar as reticências apenas se forem seguidas de nova frase, e
    # se não começarem uma frase elas próprias trata também das
    # reticências antes de aspas
    s/([\w\d!?])§(["»]*) ([^»"a-záéíóúâêà,;?!)])/$1§$2.$3/g;

    # aqui trata das frases acabadas por aspas, eventualmente tb
    # fechando parênteses e seguidas por reticências
    s/([\w!?]["»])§(\)*) ([^»"a-záéíóúâêà,;?!)])/$1§$2.$3/g; 

    # tratar dos dois pontos: apenas se seguido por discurso directo
    # em maiúsculas
    s/: (\«)([A-ZÁÉÍÓÚÀ])/:.$1$2/g; # fiz aqui algumas jiga-jogas para
                                    # que o emacs me colorize isto
                                    # direito! :)

    s/: (\-\-[ \«]*[A-ZÁÉÍÓÚÀ])/:.$1/g;

    # tratar dos dois pontos se eles acabam o parágrafo (é preciso pôr
    # um espaço)
    s/:\s*$/:. /;

    # tratar dos pontos antes de aspas
    s/\.(["»])([^.])/+$1.$2/g;

    # tratar das aspas quando seguidas de novas aspas
    s/(\»)\s*([\«"])/$1. $2/g; # fiz aqui algumas jiga-jogas para que
                               # o emacs me colorize isto direito! :)

    # tratar de ? e ! seguidos de aspas quando seguidos de maiúscula
    # eventualmente iniciados por abre parênteses ou por travessão
    s/([?!])([»"]) ((?:\(|\-\- )*[A-ZÁÉÍÓÚÀÊÂ])/$1$2. $3/g;

    # separar os pontos ? e ! antes de parênteses e possivelmente
    # aspas se forem o fim do parágrafo
    s/(\w[?!]+)([)][»"]*) *$/$1 $2./;

    # tratar dos pontos antes de aspas precisamente no fim
    s/\.([»"])\s*$/+$1. /g;

    # tratar das reticências e outra pontuação antes de aspas
    # precisamente no fim
    s/([!?§])([»"])\s*$/$1$2. /g;

    #tratar das reticências precisamente no fim
    s/§\s*$/§. /g;

    # tratar dos pontos antes de parêntesis precisamente no fim
    s/\.\)\s*$/+\). /g;

    # aqui troco .) por .). ...
    s/\.\)\s/+\). /g;
  }

  # tratar de parágrafos que acabam em letras, números, vírgula ou
  # "-", chamando-os fragmentos #ALTERACAO
  my $fragmento;
  $fragmento = 1 if $par =~/[A-Za-záéíóúêãÁÉÍÓÚÀ0-9\),-][»\">]*\s*\)*\s*$/;

  for ($par) {
    # se o parágrafo acaba em "+", deve-se juntar "." outra vez.
    s/([^+])\+\s*$/$1+. /;

    # se o parágrafo acaba em abreviatura (+) seguido de aspas ou
    # parêntesis, deve-se juntar "."
    s/([^+])\+\s*(["»\)])\s*$/$1+$2. /;
  }

  my @sentences = split/\./,$par;
  if (($#sentences > 0) and not $fragmento) {
    pop(@sentences);
  }

  my $resultado = "";
  my $num_frase_no_paragrafo = 0; # para saber em que frase pôr <s frag>
  foreach my $frase (@sentences) {
    $frase = recupera_ortografia_certa($frase);

    if ( ($frase=~/[.?!:;][»"]*\s*$/) or ($frase=~/[.?!] *\)[»"]*$/) )
      {
	# frase normal acabada por pontuação
	$resultado.="<s> $frase </s>\n";
      }
    elsif (($fragmento) and ($num_frase_no_paragrafo == $#sentences))
      {
	$resultado.="<s frag> $frase </s>\n";
	$fragmento=0;
      }
    else
      {
	$resultado.="<s> $frase . </s>\n";
      }
    $num_frase_no_paragrafo++;
  }

  $resultado;
}


sub protege_atr_estruturais {
  my $linha_CQP = shift;

  for ($linha_CQP) {
    # para tratar os atributos que têm <qq num= b= ...>
    s/ /_/g if $linha_CQP=~/^<[^>]*=/;

    # tratar os atributos que podem aparecer no meio do texto
    # especialmente
    s/<marca num/<marca_num/g;
    s/<notetrad cont=/<notetrad_cont=/g;
    s/<place /<place_/g;
    s/<reord /<reord_/g;

    if (/^<[a-zA-Z0-9]+ \"[ A-ZÊÁÉÍÓÚÀÇÔÕÃÂa-zôõçáéíóúâêàã0-9.-]+\">/) {
      # para tratar os atributos da forma <nome "ola ola">...
      s/ /_/g;
    } else {
      # tratar todos os atributos da forma <nome valor>
      s/^<([a-zA-Z0-9]+) ([a-zA-Z0-9-]+)>/<$1_$2>/;
    }
  }
  $linha_CQP;
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

  printPN(@options);
  printPNstring({ %options... } ,$textstrint);
  printPNstring([ @options... ] ,$textstrint);

  forPN( sub{my ($pn, $contex)=@_;... } ) ;
  forPN( {t=>"double"}, sub{my ($pn, $contex)=@_;... }, sub{...} ) ;

  forPNstring(sub{my ($pn, $contex)=@_;... } ,$textstring, regsep) ;

  $st = syllable($phrase);
  $s = accent($phrase);
  $s = wordaccent($word);

  $s = xmlsentences($textstring);
  $s = xmlsentences({st=>"frase"},$textstring);
  @s = sentences($textstring);


  perl -MLingua::PT::PLN -e 'cqptokens("file")' > out

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

=head2 C<syllable( $phrase )>

Returns the phrase with the syllables separated by "|"

=head2 C<accent( $phrase )>

Returns the phrase with the syllables separated by "|" and accents marked with
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

Linguateca (http://www.linguateca.pt) e Projecto Natura (http://natura.di.uminho.pt)

Alberto Simoes (albie@alfarrabio.di.uminho.pt)

Diana Santos (diana.santos@sintef.no)

José João Almeida (jj@di.uminho.pt)

Paulo Rocha (paulo.rocha@di.uminho.pt)

=head1 SEE ALSO

perl(1).
cqp(1).

=cut
