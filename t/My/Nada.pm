package My::Nada;

use Apache::RequestRec ();
use Apache::Const -compile => 'OK';

use strict;

sub print {

  my ($r, @args) = @_;

  $r->print('');

  return Apache::OK;
}

sub PRINT {

  print '';

  return Apache::OK;
}

1;
