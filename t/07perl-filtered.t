use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp t_write_perl_script);

use File::Spec::Functions qw(catfile);

# test mod_cgi + #perl + custom filter

plan tests => 1, (need_lwp && 
                  need_cgi &&
                  need_module('mod_perl.c') &&
                  need_module('include'));

my @lines = <DATA>;
my $file = catfile(Apache::Test::vars('serverroot'),
                   qw(cgi-bin include.cgi));

t_write_perl_script($file, @lines);

my $response = GET '/cgi-bin/include.cgi';
chomp(my $content = $response->content);

ok t_cmp($content,
         'cgi *** one *** generated with filter',
         "mod_cgi + #perl + filter");

__END__
print "Content-Type: text/html\n\n";
print 'cgi <!--#perl arg="one" sub="My::PrintArgs"--> generated';
