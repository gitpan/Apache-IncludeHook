use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp t_write_file);

use File::Spec::Functions qw(catfile);

# Options +IncludesNOEXEC

plan tests => 1, (have_lwp &&
                  have_module('include'));

foreach my $file (qw(normal)) {
  my $line = <DATA>;

  t_write_file(catfile('htdocs', "perl-noexec-$file.shtml"), $line);

  my $response = GET "/noexec/perl-noexec-$file.shtml";
  chomp(my $content = $response->content);

  ok t_cmp(q!perl [an error occurred while processing this directive] here!,
           $content, 
           $line);
}

__END__
perl <!--#perl arg="one" sub="My::PrintArgs" --> here
