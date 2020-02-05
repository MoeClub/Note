#!/usr/bin/perl 
use strict;
use warnings;
use File::Copy qw(move);


sub license {
	print "\n".
	"License:\n\n".
	"\tName:\t\tHaibaraAi\n".
	"\tCompany:\tHaibaraAi\n".
	"\tSerial Number:\t03-30-037937\n".
	"\tLicense Key:\tABYSEB EHYNVC V4YWBD FFG6YM ACJYTB Z6NZTP 3SHAP6 FB9V2V\n".
	"\tIssue Date:\t11-06-2019\n\n\n";
}

sub usage {
    print "\n".
	"help:\n\n".
	"\tperl securecrt_crack.pl <file>\n\n\n".
    "\n";
	
	&license;

    exit;
}
&usage() if ! defined $ARGV[0] ;


my $file = $ARGV[0];

open FP, $file or die "can not open file $!";
binmode FP;

open TMPFP, '>', '/tmp/.securecrt.tmp' or die "can not open file $!";

my $buffer;
my $unpack_data;
my $crack = 0;

while(read(FP, $buffer, 2048)) {
	$unpack_data = unpack('H*', $buffer);
	if ($unpack_data =~ m/785782391ad0b9169f17415dd35f002790175204e3aa65ea10cff20818/) {
		$crack = 1;
		last;
	}
	if ($unpack_data =~ s/6e533e406a45f0b6372f3ea10717000c7120127cd915cef8ed1a3f2c5b/785782391ad0b9169f17415dd35f002790175204e3aa65ea10cff20818/ ){
		$buffer = pack('H*', $unpack_data);
		$crack = 2;
	}
	syswrite(TMPFP, $buffer, length($buffer));
}

close(FP);
close(TMPFP);

if ($crack == 1) {
		unlink '/tmp/.securecrt.tmp' or die "can not delete files $!";
		print "It has been cracked\n";
		&license;
		exit 1;
} elsif ($crack == 2) {
		move '/tmp/.securecrt.tmp', $file or die 'Insufficient privileges, please switch the root account.';
		chmod 0755, $file or die 'Insufficient privileges, please switch the root account.';
		print "crack successful\n";
		&license;
} else {
	die 'error';
}
