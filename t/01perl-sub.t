use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp t_write_file);

use File::Spec::Functions qw(catfile);

# <!-- #perl sub="..."--> tests

plan tests => 9, (need_lwp &&
                  need_module('mod_perl.c') &&
                  need_module('include'));

foreach my $file (qw(empty die undefined good multi named method anondie anongood)) {
  my $line = <DATA>;

  my ($ok, $html) = split /\Q|/, $line;
  chomp(my $test = $html);

  if ($html =~ m/sub \{$/) {
    # slurp up final anon sub
    $test .= '...} -->';
    $html .= join '', <DATA>;
  }

  my @args = $html =~ m/arg="([^\"]+)"/g;
  my $argstring = @args ?
                  join ' : ', @args :
                  'no args';

  t_write_file(catfile(Apache::Test::vars('serverroot'),
                       'htdocs', "perl-sub-$file.shtml"), $html);

  my $response = GET "/ssi/perl-sub-$file.shtml";
  chomp(my $content = $response->content);

  ok t_cmp($content,
           $ok                                ? 
             qq!perl *** $argstring *** here! :
             q!perl [an error occurred while processing this directive] here!,
           $test);
}

# format:
# ok, content
# where   ok: 1 should pass, 0 should error
__END__
0|perl <!--#perl sub="" --> here
0|perl <!--#perl sub="My::Die" --> here
0|perl <!--#perl sub="My::Whoa" --> here
1|perl <!--#perl sub="My::PrintArgs" --> here
0|perl <!--#perl sub="My::PrintArgs" sub="My::PrintArgs" --> here
1|perl <!--#perl sub="My::PrintArgs::othername" --> here
1|perl <!--#perl sub="My::PrintArgs->method_handler" --> here
0|perl <!--#perl sub="sub { die }" --> here
1|perl <!--#perl sub="sub {

  my ($r, @args) = @_;

  $args[0] = 'no args' unless @args;

  $r->print(join ' ', '***', (join ' : ', @args), '***');

  return Apache2::Const::OK;

}" --> here
