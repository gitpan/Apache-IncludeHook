use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp t_write_file);

use File::Spec::Functions qw(catfile);

# <!-- #perl arg="foo" sub="..."--> tests
# where sub prints ''

plan tests => 2, (have_lwp &&
                  have_module('mod_perl.c') &&
                  have_module('include'));

foreach my $file (qw(print PRINT)) {
  my $line = <DATA>;

  t_write_file(catfile(Apache::Test::vars('serverroot'),
                       'htdocs', "perl-nada-$file.shtml"), $line);

  my $response = GET "/ssi/perl-nada-$file.shtml";
  chomp(my $content = $response->content);

  ok t_cmp(q!perl  here!,
           $content, 
           $line);
}

__END__
perl <!--#perl sub="My::Nada::print" --> here
perl <!--#perl sub="My::Nada::PRINT" --> here
