use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp t_write_file);

use File::Spec::Functions qw(catfile);

# tests for handlers that run subrequests

plan tests => 5, (have_lwp &&
                  have_module('include') &&
                  have { 'subrequests under construction' => 0 } );

t_write_file(catfile('htdocs', 'flat.shtml'), 
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

  t_write_file(catfile('htdocs', "perl-subreq-$file.shtml"), $html);

  my $response = GET "/ssi/perl-subreq-$file.shtml";
  chomp(my $content = $response->content);

  ok t_cmp($ok ? 
             $ok == 1 ? 
             'ECHO... ECHO... ECHO' :
             '<!-- #echo var="INCLUDE_HOOK" -->' :
           q!perl [an error occurred while processing this directive] here!,
           $content, 
           $test);
#exit;
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

  use Apache::RequestRec ();
  use Apache::SubRequest ();

  my ($r, $uri) = @_;

  $r->lookup_uri($uri);
  $r->run;

  return Apache::OK;
}" --> here

