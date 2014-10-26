# -*- cperl -*-
package Lingua::PT::PLN::Words2Sampa;
use strict;
use Text::RewriteRules;

our ($vg, $con);

BEGIN{
  $vg='[@6EOQUaeiouw�����������]'  ;
  $con='[SJLRZdrstpsfgjklzcvbnm�]' ; # consoante menos h
}

#foneticos (SAMPA) S=x J=nh L=lh R=rr O=� E=� Z=j
#auxiliares meus Q=e/3 I=i_dos_ditongos U=u_semivogal

sub run{
  my $a = shift;
  my $debug = shift || 0;
  print "\nttf:'$a'=" if $debug;
  $b=_b(_a($a));
  #  $b=~ s/(($vg|$con)~?:?)/$1 /g;
  print $b if $debug;
  $b;
}

RULES _a

# �==>a:n
lh==>L
ch==>S
nh==>J
�==>J

qu(:?)(o~?[nm])==>kw$2$1
qu(:?)o==>kuO$1
qu(:?)([a���6]~?)==>kw$2$1
qu(:?)([ei���\@]~?)==>k$2$1
qu?==>k

c([Eei���\@])==>�$1

ass==>6ss
ss==>�
^ho==>O
^o:==>O:
^h==>
�:?o==>6~:w~
�:?e==>6~:I~

osi==>uzi
^act==>_act
^al($con)==>_al$1
^a($con)==>6$1

rr==>R
^r==>R
([nls])r==>$1R
el$==>El
([aEei])([rl])$==>$1:$2!! $_!~/:/

^es($con)==>iS$1
e[xS](?=[cp])==>6IS
^e([nmui])==>_e$1
^e(?![:~])==>i

g([ei���\@])==>Z$1
gu(:?)([ei���\@])==>g_$2$1

#($vg)(:?)([nm])($con)==>$1~$2$3$4
($vg)(:?)([nm])($con)==>$1~$2$4
a(:?)[nm]$==>6~$1w~
a~==>6~
O~==>o~
#�(:?)e==>o$1ein
�(:?)e==>o:e~I~n
[e�](:?)m$==>6~$1I~
($vg)m$==>$1~

ec�==>E�
c�==>�

# e(:?)Z==>6$1IZ

sZ==>j
j==>Z
ct==>t

ba==>b6
($vg)(:?)s($vg)==>$1$2z$3
esc==>esk

s([Z])==>$1
s([bdgvZzlRmnJL])==>Z$1

s($con)==>S$1
^([ie\@])x([ioae])==>iz$2
e:xo==>e:kso
exo==>ekso
#($vg)x($vg)==>$1z$2
($vg)(:?)x($vg)==>$1$2S$3

o:z$==>OS
z$==>:S
x$==>S

os$==>uS
as$==>6S
es$==>\@S
o$==>u
a$==>6
e$==>\@
a(:?)i(?!:)==>a$1I
a(:?)u==>a$1w
e(:?)i==>6$1I
e(:?)u==>e$1w
o(:?)[a6](S?)$==>o$1u6$2
o(:?)i==>o$1I
ou==>ow
u(:?)i(?!:)==>u$1I
y==>i
s$==>S

ENDRULES

RULES _b

e(?![:~wIj])==>@
o(?![:~wIj])==>u
a(?![:~wIj])==>6

�==>s
c==>k
x==>S
I==>j
h==>

�==>a:
�==>a:

�==>E:
�==>i:
�==>O:
�==>u:
�==>6~:
�(~?)==>6~:
�~==>e~:
�(:?)n==>e~:n
�==>e:
�~==>o~:
�(:?)n==>o~:n
�==>o:
::==>:
_==>

ENDRULES

1;

__END__

=head1 NAME

Words2Sampa - Perl extension for 

=head1 SYNOPSIS

 use Lingua::PT::PLN::Words2Sampa;
 print Lingua::PT::PLN::Words2Sampa::run("word")

 perl -MLingua::PT::PLN::Words2Sampa \
   -e 'print Lingua::PT::PLN::Words2Sampa::run(shift)' mesa

=head1 DESCRIPTION

=head2 EXPORT

=head2 function run

 run(word, debug?)

=head1 AUTHOR


=head1 SEE ALSO

perl(1).

=cut      
