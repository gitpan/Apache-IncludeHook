#!perl

use 5.008;

use Apache2 ();
use ModPerl::MM ();
use Apache::TestMM qw(test clean);
use Apache::TestRunPerl ();

# configure tests based on incoming arguments
Apache::TestMM::filter_args();

# provide the test harness
Apache::TestRunPerl->generate_script();

# now, write out the Makefile
ModPerl::MM::WriteMakefile(
  NAME          => 'Apache::IncludeHook',
  VERSION_FROM  => 'IncludeHook.pm',
  PREREQ_PM     => { mod_perl    => 1.9910 },
);
