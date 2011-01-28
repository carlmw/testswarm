#!/usr/bin/perl
use strict;
use DBI;
use Getopt::Long;

my %options;
my $job_name;
my $build_number;
my $svn_revision;
my $workspace;
my $browsers;

unless (GetOptions(\%options, "job=s" => \$job_name,
				              "build:i" => \$build_number,
				              "revision:i" => \$svn_revision,
				              "workspace:s" => \$workspace,
				              "browsers:s" => \$browsers)){
	die	"Error parsing commandline"
}

my $HOST = "localhost";
my $DATABASE = "testswarm";
my $USER = "testswarm";
my $PASSWORD = "ressig";
my $PORT = "8999";

# The maximum number of times you want the tests to be run.
my $MAX_RUNS = 1;

# The browsers you wish to run against. Options include:
# - "all" all available browsers.
# - "popular" the most popular browser (99%+ of all browsers in use)
# - "current" the current release of all the major browsers
# - "gbs" the browsers currently supported in Yahoo's Graded Browser Support
# - "beta" upcoming alpha/beta of popular browsers
# - "mobile" the current releases of mobile browsers
# - "popularbeta" the most popular browser and their upcoming releases
# - "popularbetamobile" the most popular browser and their upcoming releases and mobile browsers
my $BROWSERS = "popular";

# All the suites that you wish to run within this job
# (can be any number of suites)

## insert static suite list here
my %SUITES = (	'core' => 'http://localhost:8999/jquery/test/index.html?core',
				'data' => 'http://localhost:8999/jquery/test/index.html?data',
				'queue' => 'http://localhost:8999/jquery/test/index.html?queue',
				'attributes' => 'http://localhost:8999/jquery/test/index.html?attributes',
				'event' => 'http://localhost:8999/jquery/test/index.html?event',
				'selector' => 'http://localhost:8999/jquery/test/index.html?selector',
				'traversing' => 'http://localhost:8999/jquery/test/index.html?traversing',
				'manipulation' => 'http://localhost:8999/jquery/test/index.html?manipulation',
				'css' => 'http://localhost:8999/jquery/test/index.html?css',
				'ajax' => 'http://localhost:8999/jquery/test/index.html?ajax',
				'effects' => 'http://localhost:8999/jquery/test/index.html?effects',
				'offset' => 'http://localhost:8999/jquery/test/index.html?offset',
				'dimensions' => 'http://localhost:8999/jquery/test/index.html?dimensions',
			  );

# Comment these out if you wish to define a custom set of SUITES above
## REPLACE local
#my $SUITE = "http://localhost:8002/test/unit/glow";

#sub BUILD_SUITES {
#%SUITES = map { /(\w+).js$/; $1 => "$SUITE/*.html?$1"; }
#grep { $_ !~ /ajax/; } glob("../glow2/test/unit/glow/*.js");
#}


########### NO NEED TO CONFIGURE BELOW HERE ############
my $dsn = "DBI:mysql:database=$DATABASE;host=$HOST;port=3306";
my $dbh = DBI->connect($dsn, $USER, $PASSWORD);

my $query = "SELECT auth FROM users WHERE name='hudson'";
my $sth = $dbh->prepare($query);
$sth->execute();
my $numRows = $sth->rows;



unless ($numRows = 1){
	die 'Unable to get Auth token from testswarm database'
}
my @result = $sth->fetchrow_array();
my $AUTH_TOKEN = $result[0];

#print $AUTH_TOKEN;

my $SWARM = "http://" . $HOST . ":" . $PORT . "/";
my $DEBUG = 1;

my %props = (
"output" => "dump",
"user" => "hudson",
"max" => $MAX_RUNS,
"job_name" => $job_name,
"browsers" => $BROWSERS,
"auth" => $AUTH_TOKEN,
"state" => "addjob",
);

my $queryString = "";

foreach my $prop ( keys %props ) {
	print $prop . " : " . $props{$prop} . "\n";
	$queryString .= ($queryString ? "&" : "") . $prop . "=" . clean($props{$prop});
}

foreach my $suite ( sort keys %SUITES ) {
$queryString .= "&suites[]=" . clean($suite) .
"&urls[]=" . clean($SUITES{$suite});
}

print "curl -d \"$queryString\" $SWARM\n" if ( $DEBUG );
my $results = `curl -d "$queryString" $SWARM`;
print "Results: $results\n" if ( $DEBUG );

if ( $results ) {
	#$done{ $rev } = 1;

} else {
print "Job not submitted properly.\n";
}

sub clean {
	my $str = shift;
	my $rev = shift;
	my $frev = shift;

	$str =~ s/{REV}/$rev/g;
	$str =~ s/{FREV}/$frev/g;
	$str =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
	$str;
}