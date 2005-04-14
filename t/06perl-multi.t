use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp t_write_file);

use File::Spec::Functions qw(catfile);

# multi-tag tests

plan tests => 3, (need_lwp &&
                  need_module('mod_perl.c') &&
                  need_module('include'));

my @lines = <DATA>;

foreach my $file (qw(one two three)) {

  my @file = splice(@lines, 0, 3);

  my $output;

  foreach (@file) {

    my ($ok, $html) = split /\Q|/;

    $_ = $html;

    my @args = $html =~ m/arg="([^\"]+)"/g;
    my $argstring = @args ? 
                    join ' : ', @args :
                    'no args';

    $output .= $ok ?
               qq!perl *** $argstring *** here! :
               q!perl [an error occurred while processing this directive] here!;

    $output .= "\n";
  }

  chomp $output;

  t_write_file(catfile(Apache::Test::vars('serverroot'),
                       'htdocs', "perl-multi-$file.shtml"), @file);

  my $response = GET "/ssi/perl-multi-$file.shtml";
  chomp(my $content = $response->content);

  ok t_cmp($content,
           $output,
           "die in tag $file");
}

# format:
# ok, content
# where   ok: 1 should pass, 0 should error
__END__
0|perl <!--#perl arg="one" sub="My::Die" --> here
1|perl <!--#perl arg="two" sub="My::MultiPrintArgs" --> here
1|perl <!--#perl arg="three" sub="My::MultiPrintArgs" --> here
1|perl <!--#perl arg="one" sub="My::MultiPrintArgs" --> here
0|perl <!--#perl arg="two" sub="My::Die" --> here
1|perl <!--#perl arg="three" sub="My::MultiPrintArgs" --> here
1|perl <!--#perl arg="one" sub="My::MultiPrintArgs" --> here
1|perl <!--#perl arg="two" sub="My::MultiPrintArgs" --> here
0|perl <!--#perl arg="three" sub="My::Die" --> here
