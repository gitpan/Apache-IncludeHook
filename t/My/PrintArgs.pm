package My::PrintArgs;

use Apache::RequestRec ();
use Apache::Const -compile => 'OK';

use strict;

sub handler {

  my ($r, @args) = @_;

  $args[0] = 'no args' unless @args;

#  $r->print(join ' ', '***', (join ' : ', @args), '***');
  print join ' ', '***', (join ' : ', @args), '***';

  return Apache::OK;
}

sub method_handler : method {

  my $class = shift;

  return handler(@_);
}

sub othername {
  return handler(@_);
}

1;
