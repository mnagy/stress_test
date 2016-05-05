#!/usr/bin/perl

use Math::Round;

round(10.2) == 10 || die "round(10.2) != 10";

my $str = "Hello world!";
#foreach my $i (0..$ENV{"QUERY_STRING"}) {
foreach my $i (0..$ENV{"TEST_EXP"}) {
   $str = $str . " " . $str;
}
$str = $str . "\n";

sleep($ENV{"TEST_SLEEP"});

print "Content-type: text/html\n\n";
print <<EOF
<html>
<head><title>Everything is OK</title></head>
<body>
Everything is fine. Here's a string:
$str
</body>
</html>
EOF
;
