package Lingua::PT::PLN::tokenizer;
##
#     (regexp, fstruct, ruleid)*
##

our $tab = [
	['(www|(ht|f)tps?://[a-zA-Z_0-9=:/~\-]+)(\.[a-zA-Z_0-9=:/~\-]+)+' => "[CAT=np,SUBCAT=url]", "url"],
	['[a-zA-Z_.0-9]+\@[a-zA-Z_0-9=:/~\-]+(\.[a-zA-Z_0-9=:/~\-]+)+' => "[CAT=np,SUBCAT=email]", "email"],


	['--+' => "[CAT=pont, SUBCAT=travessao]", "pont"],

	['\[\.\.+\]' => "[CAT=pont, SUBCAT=??]", "pont"],

	['\d{1,2}h(\d{1,2}((m\d{1,2}s?)|m)?)?' => "[CAT=tempo, SUBCAT=hora]", "tempo"],
	['\d+min' => "[CAT=tempo, SUBCAT=minutos]", "tempo"],
	['\d+m\d+[,.]\d+s' => "[CAT=tempo, SUBCAT=minutos]", "tempo"],

	['\d+([,.]\d+)?%' => "[CAT=num, SUBCAT=perc]", "num"],
	['\d+.?[ºªao].?' => "[CAT=num, SUBCAT=ord]", "num"],

	['\d+C'=> "[CAT=num, SUBCAT=graus]", "num"],

	['\d{1,4}[-./]\d{1,2}[-./]\d{1,4}\b' => "[CAT=tempo, SUBCAT=data]", "tempo"],

	['T[0-7](\+1)\b' => "[CAT=np, SUBCAT=apart]", "apar"],
	['A\d+' => "[CAT=np, SUBCAT=papel]", "papel"],

	['\d+\$\d+' => "[CAT=num, SUBCAT=money]", "num"],

	['\d{3}-\d{3}-\d{3}\b' => "[CAT=np, SUBCAT=tel]", "tel"],

	['\d+([,.]\d+)?' => "[CAT=num, SUBCAT=card]", "num"],

	['[/.!?;,:()]+' => "[CAT=pont]", "pont"],

	['[«»`\x93\x94"]|(?:\B\'\B)' => "[CAT=aspa]", "aspa"],

	['[À]' => "[CAT=cp,Prep=a,Art=a,G=f,N=s]", "auch"],

       ];

1;
__END__
