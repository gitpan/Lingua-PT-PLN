use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'Lingua::PT::PLN',
    'VERSION_FROM' => 'PLN.pm',
    'PREREQ_PM'	   => {},
    'EXE_FILES'    => ['pt-tokenizer'],
);
