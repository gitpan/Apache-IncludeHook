use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp t_write_perl_script);

use File::Spec::Functions qw(catfile);

# test mod_cgi + #perl + custom filter

plan tests => 1, (have_lwp && 
                  have_cgi &&
                  have_module('include'));

my @lines = <DATA>;
t_write_perl_script(catfile(qw(cgi-bin include.cgi)), @lines[0,1]);

my $response = GET '/cgi-bin/include.cgi';
chomp(my $content = $response->content);

ok t_cmp('cgi *** one *** generated with filter',
         $content,
         "mod_cgi + #perl + filter");

__END__
print "Content-Type: text/html\n\n";
print 'cgi <!--#perl arg="one" sub="My::PrintArgs"--> generated';
