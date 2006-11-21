use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'Lingua::PT::PLN',
    'VERSION_FROM' => 'PLN.pm',
    'PREREQ_PM'	   => {
		       Lingua::PT::PLNbase => 0.17,
		      },
    'EXE_FILES'    => ['bin/pt-tokenizer','bin/occurrences'],
);
