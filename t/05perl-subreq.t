use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp t_write_file);

use File::Spec::Functions qw(catfile);

# tests for handlers that run subrequests

plan tests => 4, (need_lwp &&
                  need_module('mod_perl.c') &&
                  need_module('include'));

t_write_file(catfile(Apache::Test::vars('serverroot'),
             'htdocs', 'flat.shtml'), 
             '<!-- #echo var="INCLUDE_HOOK" -->');

foreach my $file (qw(flat noexec parsed anon)) {
  my $line = <DATA>;

  next if $line =~ m/^#/;

  my ($ok, $html) = split /\Q|/, $line;
  chomp(my $test = $html);

  if ($html =~ m/sub \{$/) {
    # slurp up final anon sub
    $test .= '...} -->';
    $html .= join '', <DATA>;
  }

  t_write_file(catfile(Apache::Test::vars('serverroot'),
                       'htdocs', "perl-subreq-$file.shtml"), $html);

  skip ('subrequests will not invoke the SSI engine (yet)', 1) && next
    unless $file eq 'flat';

  my $response = GET "/ssi/perl-subreq-$file.shtml";
  chomp(my $content = $response->content);

  ok t_cmp($content,
           $ok                                     ? 
             $ok == 1                 ? 
               'ECHO... ECHO... ECHO' :
               'perl <!-- #echo var="INCLUDE_HOOK" --> here' :
             q!perl [an error occurred while processing this directive] here!,
           $test);
}

# format:
# ok, content
# where   ok: 0, error
#             1, pass with parsed content
#             2, pass with unparsed content
#             
__END__
2|perl <!--#perl arg="/flat.shtml" sub="My::Subrequest" --> here
0|perl <!--#perl arg="/noexec/flat.shtml" sub="My::Subrequest" --> here
1|perl <!--#perl arg="/ssi/flat.shtml" sub="My::Subrequest" --> here
1|perl <!--#perl arg="/ssi/flat.shtml" sub="sub {

  use Apache2::RequestRec ();
  use Apache2::SubRequest ();

  my ($r, $uri) = @_;

  $r->lookup_uri($uri)->run;

  return Apache2::Const2::OK;
}" --> here

