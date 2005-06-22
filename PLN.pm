package Lingua::PT::PLN;

use strict;
require Exporter;
our @ISA = qw(Exporter AutoLoader);

our @EXPORT = qw(
   syllable accent wordaccent

   xmlsentences sentences

   cqptokens tokenize

   oco
);
our $VERSION = '0.11';

use locale;

our ($consoante, $vogal, $np1, $np, @stopw , %vazia , $prof, $adje, $em, $e, $sep1, $sep2, %names, %gnames);


BEGIN {
  $consoante='[bcÁdfghjklmÒnpqrstvwyxz]';
  $vogal='[·ÈÌÛ˙‚ÍÙ„ı‡aeiou]';

  $np1=qr{(?:(?:[A-Z…⁄”¡¬][.])+|[sS]r[.]|[dD]r[.]|St[oa]?[.]|[A-Z…⁄”¡¬]\w+(?:[\'\-]\w+)*)};

  if ($e) {
    $np= qr{$np1(?:\s+(?:d[eao]s?\s+|e\s+)?$np1)*};
  } else {
    $np= qr{$np1(?:\s+(?:d[eao]s?\s+)?$np1)*};
  }

  use POSIX;
  POSIX::setlocale(LC_CTYPE,"pt_PT");

  @stopw = qw{
              no com se em segundo a o os as na nos nas do das dos da tanto
              para de desde mas quando esta sem nem sÛ apenas mesmo atÈ uma uns um
              pela por pelo pelas pelos depois ao sobre como umas j· enquanto aos
              tambÈm amanh„ ontem embora essa nesse olhe hoje n„o eu ele eles
              primeiro simplesmente era foi È ser· s„o seja nosso nossa nossos nossas
              chama-se chamam-se subtitui resta diz salvo disse diz vamos entra entram
              aqui comeÁou l· seu vinham passou quanto sou vi onde este ent„o temos
              num aquele tivemos
              the le la
             };


  $prof = join("|", qw{
                       astrÛlogo astrÛnomo advogado actor
                       baterista
                       cantor compositor
                       dramaturgo
                       engenheiro escritor
                       filÛsofo flautista fÌsico
                       investigador
                       jogador
                       matem·tico mÈdico ministro m˙sico
                       pianista poeta professor
                       quÌmico
                       teÛlogo
                      });

  $adje = join("|", qw{
                       portuguÍs francÍs inglÍs espanhol
                       internacional bracarence minhoto
                      });

  $sep1 = join("|", qw{chamado "conhecido como"});

  $sep2 = join("|", qw{brilhante conhecido reputado popular});

  @vazia{@stopw} = (@stopw); # para ser mais facil ver se uma pal È stopword
  $em = '\b(?:[Ee]m|[nN][oa]s?)';
}



sub oco {
  ### { from => (file|string),
  ###    num => 1,
  ###  alpha => 1,
  ### output => file,
  ### ignorexml => 1,
  ### ignorecase => 1}

  my %opt = (from => 'file', ignorecase => 0, ignorexml => 0);
  %opt = (%opt , %{shift(@_)}) if ref($_[0]) eq "HASH";

  local $\ = "\n";                    # set output record separator

  my $P="(?:[,;:?!]|[.]+|[-]+)";      # pontuacao a contar
  my $A="[A-ZÒ—a-z·‡„‚ÁÈËÍÌÛÚıÙ˙˘˚¡¿√¬«…» Õ”“’‘⁄Ÿ€]";
  my $I="[ \"(){}+*=<>\250\256\257\277\253\273]"; # car. a  ignorar
  my %oco=();

  if ($opt{from} eq 'string') {
    my (@str) = (@_);
    for (@str) {
      $_ = lc if $opt{ignorecase};
      s/<[^>]+>//g if $opt{ignorexml};
      for (/($A+(?:['-]$A+)*|$P)/g) { $oco{$_}++; }
    }
  } else {
    my (@file) = (@_);
    for(@file) {
      open F,"< $_" or die "cant open $_: $!";
      while (<F>) {
	$_ = lc if $opt{ignorecase};
      s/<[^>]+>//g if $opt{ignorexml};
        for (/($A+(?:['-]$A+)*|$P)/g) { $oco{$_}++; }
      }
      close F;
    }
  }

  if ($opt{num}) { # imprime por ordem de quantidade de ocorrencias

    # TODO: n„o È port·vel
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


sub accent{
  local $/ = "";           # input record separator=1 or more empty lines
  my $p=shift;
  $p =~ s/(\w+)/ wordaccent($1) /ge;
  $p
}

sub wordaccent{
  my $p=syllable(shift);
  for ($p){
    s/(\w*[·ÈÌÛ˙Ù‚Í„ı])/"$1/        or  # word with an accent character
      s/(\w*)([ua])(ir)$/$1$2|"$3/  or  # word ending with air uir
	s/(\w*([zlr]|[iu]s?))$/"$1/ or  # word ending with z l r i u is us
	  s/(\w+\|\w+)$/"$1/        or  # accent in 2 syllable frm the end
	    s/(\w)/"$1/;                # accent in the only syllable

    s/"(($consoante)*($vogal|[yw]))/$1:/ ;
    s/"qu:($vogal|[yw])/qu$1:/ ;
    s/:([·ÈÌÛ˙Ù‚Í„ı])/$1:/  ;
    s/"//g;

  }
  $p
}

my %syl = (
	   20 => " -.!?:;",
	   10 => "bÁdfgjkpqtv",
	   7 => "sc",
	   6 => "m",
	   5 => "rnlzx",
	   4 => "h",
	   3 => "wy",
	   2 => "eao·ÈÌÛ˙Ù‚Í˚‡„ı‰ÎÔˆ¸",
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

my $terminador='([.?!;:]+[ª]?|<[pP]\b.*?>|<br>)';

my $protect = '
       \#n\d+
    |  \w+\'\w+
    |  [\w_.-]+ \@ [\w_.-]+\w                     # emails
    |  \w+\.[∫™]                                  # ordinals
    |  <[^>]*>                                    # marcup XML SGML
    |  \d+(?:\.\d+)+                              # numbers
    |  \d+\:\d+                                   # the time
    |  (?:\&\w+\;)                                # entidades XML HTML
    |  ((https?|ftp|gopher)://|www)[\w_./~:-]+\w  # urls
    |  \w+(-\w+)+                                 # d·-lo-‡
';

my $abrev = join '|', qw( srt?a? dra? [A-Z] etc exa? jr profs? arq av estr?
			  et al vol no eng tv lgo pr Oliv ig mrs? min rep 
  );

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
    s#($protect)#          _savit($1)#xge;
    s#\b(($abrev)\.)#      _savit($1)#ige;
    s#($terminador)#$1$MARCA#g;
    $_=_loadit($_);
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
    if(/<(\w+)(.*?)>/) {
      ($a, $b) = ($1,$2);
      if ($b =~ /=/ )  { $tag{'v'}{$a}++ }
      else             { $tag{'s'}{$a}++ }
    }
    s/<\?xml.*?\?>//s;
    s/($protect)/_savit($1)/xge;
    s!([\ª\]])!$1 !g;
    s#([\´\[])# $1#g;
    s#\"# \" #g;
    s/(\s*\b\s*|\s+)/\n/g;
    # s/(.)\n-\n/$1-/g;
    s/\n+/\n/g;
    s/\n(\.?[∫™])\b/$1/g;
    while ( s#\b([0-9]+)\n([\,.])\n([0-9]+\n)#$1$2$3#g ){};
    s#\n($abrev)\n\.\n#\n$1\.\n#ig;
    s/\n*</\n</;
    $_=_loadit($_);
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
    s/($protect)/_savit($1)/xge;
    s#([\ª\]])#$1 #g;
    s#([\´\[])# $1#g;
    s#\"# \" #g;
    s/(\s*\b\s*|\s+)/\n/g;
    #s/(.)\n-\n/$1-/g;
    s/\n+/\n/g;
    s/\n(\.?[∫™])\b/$1/g;
    while ( s#\b([0-9]+)\n([\,.])\n([0-9]+\n)#$1$2$3#g ){};
    s#\n($abrev)\n\.\n#\n$1\.\n#ig;
    s/\n*</\n</;
    $_=_loadit($_);
    s/(\s*\n)+$/\n/;
    s/^(\s*\n)+//;
    print;
  }
  +{%tag}
}

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

__END__

$lm='[a-z·ÈÌÛ˙‚ÍÙ‡„ıÁ¸ˆÒ]';                      # letra minuscula
$lM='[A-Z¡…Õ”⁄¬ ‘¿√’«‹÷—]';                      # letra Maiuscula
$l1='[A-Z¡…Õ”⁄¬ ‘¿√’«‹÷—a-z·ÈÌÛ˙‚ÍÙ‡„ıÁ¸ˆÒ0-9]'; # letra e numero
$c1='[^ªa-z·ÈÌÛ˙‚Í‡,;?!)]';


=head1 NAME

Lingua::PT::PLN - Perl extension for NLP of the Portuguese Language

=head1 SYNOPSIS

  use Lingua::PT::PLN;

  # occurrence counter
  %o = oco("file");
  oco({num=>1,output=>"outfile"},"file");

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

=head2 C<syllable>

  my $sylls = syllable( $phrase )

Returns the phrase with the syllables separated by "|"

=head2 accent

  my $accent = accent( $phrase )

Returns the phrase with the syllables separated by "|" and accents marked with
the charater ".

=head2 wordaccent

Retuns the word splited into syllables and with the accent character marked.

=head2 setabrev

=head2 compacta

=head2 compara

=head2 tokenize

This function is a tokenizer for Portuguese text;

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

Projecto Natura (http://natura.di.uminho.pt)

Alberto Simoes (albie@alfarrabio.di.uminho.pt)

JosÈ Jo„o Almeida (jj@di.uminho.pt)

Paulo Rocha (paulo.rocha@di.uminho.pt)

=head1 SEE ALSO

perl(1).
cqp(1).

=cut
