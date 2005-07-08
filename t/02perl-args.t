use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp t_write_file);

use File::Spec::Functions qw(catfile);

# <!-- #perl arg="foo" sub="..."--> tests

plan tests => 7, (need_lwp &&
                  need_module('mod_perl.c') &&
                  need_module('include'));

foreach my $file (qw(empty if else good multi method anon)) {
  my $line = <DATA>;

  next if $line =~ m/^#/;

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
                       'htdocs', "perl-arg-$file.shtml"), $html);

  my $response = GET "/ssi/perl-arg-$file.shtml";
  chomp(my $content = $response->content);

  ok t_cmp($content,
           $ok                                ? 
             qq!perl *** $argstring *** here! :
             q!perl [an error occurred while processing this directive] here!,
           $test);
#exit;
}

# format:
# ok, content
# where   ok: 1 should pass, 0 should error
__END__
0|perl <!--#perl arg="" sub="My::PrintArgs" --> here
1|perl <!--#perl arg="one" sub="My::PrintArgs" --> here
1|<!--#if expr="1" -->perl <!--#perl arg="one" sub="My::PrintArgs" --> here<!--#else -->perl <!--#perl sub="sub {print 'must not be printed'}" --> here<!--#endif -->
1|<!--#if expr="" -->perl <!--#perl sub="sub {print 'must not be printed'}" --> here<!--#else -->perl <!--#perl arg="one" sub="My::PrintArgs" --> here<!--#endif -->
1|perl <!--#perl arg="one" arg="two" sub="My::PrintArgs" arg="three"--> here
1|perl <!--#perl arg="one" sub="My::PrintArgs->method_handler" --> here
1|perl <!--#perl sub="sub {

  my ($r, @args) = @_;

  $args[0] = 'no args' unless @args;

  $r->print(join ' ', '***', (join ' : ', @args), '***');

  return Apache2::Const::OK;

}" --> here
