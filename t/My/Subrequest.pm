package My::Subrequest;

use Apache::RequestRec ();
use Apache::SubRequest ();
use Apache::Const -compile => 'OK';

use Apache::IncludeHook;

use strict;

sub handler {

  my ($r, $uri) = @_;

  my $sub = $r->lookup_uri($uri);
  $sub->run;

  return Apache::OK;
}

1;
