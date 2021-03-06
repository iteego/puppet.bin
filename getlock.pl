#!/usr/bin/perl
use lib ("/etc/puppet/files/bin/lib");
use process_lock;

my($filename) = $ARGV[0];
my($pid) = $ARGV[1];

my($lock_success) = getlock("$filename", $pid);

if ($lock_success) {
	exit(0);
}
else {
	exit(-1);
}
