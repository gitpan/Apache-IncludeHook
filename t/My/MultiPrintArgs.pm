package My::MultiPrintArgs;

use Apache::RequestRec ();
use Apache::Const -compile => 'OK';

use strict;

sub handler {

  my ($r, @args) = @_;

  $args[0] = 'no args' unless @args;

  $r->print('*** ');
  print join ' : ', @args;
  $r->print(' ***');

  return Apache::OK;
}

1;
