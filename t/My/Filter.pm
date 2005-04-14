package My::Filter;

use Apache2::Filter ();
use Apache2::RequestRec ();
use APR::Table ();

use Apache2::Const -compile => qw(OK);

use strict;

sub handler {

  my $f = shift;
  my $r = $f->r;

  unless ($f->ctx) {
    $r->headers_out->unset('Content-Length');
    $f->ctx(1);
  }

  while ($f->read(my $buffer, 1024)) {
    $f->print($buffer);
  }

  if ($f->seen_eos) {
    $f->print(' with filter');
  }

  return Apache2::Const::OK;
}

1;
