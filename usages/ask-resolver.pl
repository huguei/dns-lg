#!/usr/bin/perl
#
# Asks a specific SOA query to specific name server.
#
# Use: ask-resolver.pl QNAME IP_SERVER
#
# Autor: @huguei
#
use strict;
use warnings;

use Net::DNS;
use HTTP::Tiny;
use JSON;

my @DNS_LG_SERVERS;

my $qname  = shift;
my $server = shift;

die "Use $0 QNAME" unless $qname;

# list of dns-lg servers
my $res   = Net::DNS::Resolver->new;
my $query = $res->query("existing-dns-lg.bortzmeyer.fr", "TXT");

if ($query) {
    foreach my $rr (grep { $_->type eq 'TXT' } $query->answer) {
        push @DNS_LG_SERVERS, $rr->char_str_list();
    }
}
else {
    die "query failed: ", $res->errorstring, "\n";
}

foreach my $URL (@DNS_LG_SERVERS) {
    my $response = HTTP::Tiny->new->get(
        $URL . $qname . '/SOA?server=' . $server . ';format=json',
        { headers => {'Accept' => 'application/json' },
          timeout => 5,
        });

    my $hostname = $1 if $URL =~ m<https*://(.*)/>;
    print $hostname, ': ';
    print 'Error! Status: ', $response->{status}, ' ', $response->{reason}, "\n"
        and next unless $response->{status} eq '200';

    my $datos = decode_json $response->{content};
    foreach my $rr (@{$datos->{AnswerSection}}) {
        print $rr->{Serial}, ' ' if $rr->{Type} eq 'SOA';
    }
    print "\n";
}

