package App::assh;

#  PODNAME: App::assh
# ABSTRACT: A wrapper around autossh.

use Moo;
use true;
use 5.010;
use strict;
use warnings;
use methods-invoker;
use MooX::Options skip_options => [qw<os cores>];
use MooX::Types::MooseLike::Base qw(:all);

has hosts => (
    is => 'lazy',
    isa => HashRef,
);

has ports => (
    is => 'lazy',
    isa => HashRef,
);

has ssh_config_file => (
    is => 'ro',
    isa => Str,
    default => sub {
        "$ENV{HOME}/.ssh/config"
    },
);

has ports_config_file => (
    is => 'ro',
    isa => Str,
    default => sub {
        "$ENV{HOME}/.autossh_rc"
    },
);

method _build_hosts {
    $_ = do { local(@ARGV, $/) = $->ssh_config_file; <>; };
    s/\s+/ /g;

    my $ret = {};
    while (m<Host\s(.+?)\sHostName\s(.+?)\sUser\s(.+?)\s>xg) {
        $ret->{$1} = { NAME => $2, USER => $3 }
    }

    return $ret;
}

method _build_ports {
    open my $portsfile, "<", $->ports_config_file or die $!;
    my $h = {};
    while(<$portsfile>) {
        chomp;
        my ($host, $port) = split;
        $h->{$host} = $port;
    }
    return $h
}

method run {
    my $host = shift;

    not defined $host and do {
        say for keys %{$->hosts};
    };

    defined $->hosts->{$host} and do {
        $->autossh_exec($host);
    };
}

method autossh_exec {
    my $host = shift;
    exec 'AUTOPOLL=5 autossh -M ' . $->ports->{$host} . ' ' . $->hosts->{$host}{USER} . '@' . $->hosts->{$host}{NAME}
}

no Moo;


=for Pod::Coverage  ports_config_file  ssh_config_file

=begin wikidoc

= SYNOPSIS

A wrapper around autossh.

= USAGE

    assh

    assh HOSTNAME

= ATTRIBUTES

* hosts: HashRef holding the values HOSTNAME => AUTOSSH_PORT

* ports: HashRef holding the values HOSTNAME => {USER => USERNAME, HOST => HOSTNAME}

* ssh_config_file: The path to the ssh config file. Default: `~/.ssh/config`

* ports_config_file: The path to the ports config (this is what I have chosen): `~/.autossh_rc`

=end wikidoc
