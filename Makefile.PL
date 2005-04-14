#!perl

use 5.008;

use ModPerl::MM ();
use Apache::TestMM qw(test clean);
use Apache::TestRunPerl ();

Apache::TestMM::filter_args();

Apache::TestRunPerl->generate_script(bugreport => <<EOF);
+-------------------------------------------------------------------+
| this module is experimental, use at your own risk                 |
+-------------------------------------------------------------------+
EOF

ModPerl::MM::WriteMakefile(
  NAME          => 'Apache::IncludeHook',
  VERSION_FROM  => 'IncludeHook.pm',
  PREREQ_PM     => { mod_perl2   => 0 },
);
