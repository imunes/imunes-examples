#!/usr/bin/perl	 

use strict;
use CGI;
my $cgi = new CGI;
print
$cgi->header() .
$cgi->start_html( -title => 'Form Results',
                          -author => 'Craig Kelley',
                          -style => '/~ink/perl_cgi/css/perlcgi.css') .
$cgi->h1('Form Results') . "\n";
my @params = $cgi->param();
print '<TABLE border="1" cellspacing="0" cellpadding="0">' . "\n";
foreach my $parameter (sort @params) {
print "<tr><th>$parameter</th><td>" . $cgi->param($parameter) . "</td></tr>\n";
}
print "</TABLE>\n";
print $cgi->end_html . "\n";
exit (0);
	  

