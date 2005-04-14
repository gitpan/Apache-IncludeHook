package My::PrintArgs;

use Apache2::RequestRec ();
use Apache2::Const -compile => 'OK';

use strict;

sub handler {

  my ($r, @args) = @_;

  $args[0] = 'no args' unless @args;

#  $r->print(join ' ', '***', (join ' : ', @args), '***');
  print join ' ', '***', (join ' : ', @args), '***';

  return Apache2::Const::OK;
}

sub method_handler : method {

  my $class = shift;

  return handler(@_);
}

sub othername {
  return handler(@_);
}

1;
