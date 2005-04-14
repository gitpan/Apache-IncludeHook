package My::Subrequest;

use Apache2::RequestRec ();
use Apache2::SubRequest ();
use Apache2::Const -compile => 'OK';

use Apache::IncludeHook;

use strict;

sub handler {

  my ($r, $uri) = @_;

  my $sub = $r->lookup_uri($uri);
  $sub->run;

  return Apache2::Const::OK;
}

1;
