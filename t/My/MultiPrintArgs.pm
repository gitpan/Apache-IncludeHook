package My::MultiPrintArgs;

use Apache2::RequestRec ();
use Apache2::Const -compile => 'OK';

use strict;

sub handler {

  my ($r, @args) = @_;

  $args[0] = 'no args' unless @args;

  $r->print('*** ');
  print join ' : ', @args;
  $r->print(' ***');

  return Apache2::Const::OK;
}

1;
