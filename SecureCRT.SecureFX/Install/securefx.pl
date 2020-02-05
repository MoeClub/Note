#!/usr/bin/perl 
use strict;
use warnings;
use File::Copy qw(move);


sub license {
	print "\n".
	"License:\n\n".
	"\tName:\t\tHaibaraAi\n".
	"\tCompany:\tHaibaraAi\n".
	"\tSerial Number:\t06-67-000807\n".
	"\tLicense Key:\tABQV61 BVG973 B8Z2EQ APQJXJ ADKDVU KPZPXA XP85BG PTJBQJ\n".
	"\tIssue Date:\t11-06-2019\n\n\n";
}

sub usage {
    print "\n".
	"help:\n\n".
	"\tperl securefx.pl <file>\n\n\n".
    "\n";
	
	&license;

    exit;
}
&usage() if ! defined $ARGV[0] ;


my $file = $ARGV[0];

open FP, $file or die "can not open file $!";
binmode FP;

open TMPFP, '>', '/tmp/.securefx.tmp' or die "can not open file $!";

my $buffer;
my $unpack_data;
my $crack = 0;

while(read(FP, $buffer, 2048)) {
	$unpack_data = unpack('H*', $buffer);
	if ($unpack_data =~ m/e02954a71cca592c855c91ecd4170001d6c606d38319cbb0deabebb05126/) {
		$crack = 1;
		last;
	}
	if ($unpack_data =~ s/c847abca184a6c5dfa47dc8efcd700019dc9df3743c640f50be307334fea/e02954a71cca592c855c91ecd4170001d6c606d38319cbb0deabebb05126/ ){
		$buffer = pack('H*', $unpack_data);
		$crack = 2;
	}
	syswrite(TMPFP, $buffer, length($buffer));
}

close(FP);
close(TMPFP);

if ($crack == 1) {
		unlink '/tmp/.securefx.tmp' or die "can not delete files $!";
		print "It has been cracked\n";
		&license;
		exit 1;
} elsif ($crack == 2) {
		move '/tmp/.securefx.tmp', $file or die 'Insufficient privileges, please switch the root account.';
		chmod 0755, $file or die 'Insufficient privileges, please switch the root account.';
		print "crack successful\n";
		&license;
} else {
	die 'error';
}
