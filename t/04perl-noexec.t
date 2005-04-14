use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp t_write_file);

use File::Spec::Functions qw(catfile);

# Options +IncludesNOEXEC

plan tests => 1, (need_lwp &&
                  need_module('mod_perl.c') &&
                  need_module('include'));

foreach my $file (qw(normal)) {
  my $line = <DATA>;

  t_write_file(catfile(Apache::Test::vars('serverroot'),
                       'htdocs', "perl-noexec-$file.shtml"), $line);

  my $response = GET "/noexec/perl-noexec-$file.shtml";
  chomp(my $content = $response->content);

  ok t_cmp($content,
           q!perl [an error occurred while processing this directive] here!,
           $line);
}

__END__
perl <!--#perl arg="one" sub="My::PrintArgs" --> here
