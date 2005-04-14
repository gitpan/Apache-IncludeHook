package My::Nada;

use Apache2::RequestRec ();
use Apache2::Const -compile => 'OK';

use strict;

sub print {

  my ($r, @args) = @_;

  $r->print('');

  return Apache2::Const::OK;
}

sub PRINT {

  print '';

  return Apache2::Const::OK;
}

1;
