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

= MOTIVATION

`autossh` is a nifty little ssh-keepalive-connection-holder.

Passing in the ports for the keepalive can be clumsy though: `assh` helps you to avoid that.

= USAGE

    assh

    assh HOSTNAME

= REQUIREMENTS

First, you will need a file `~/.ssh/config`. It looks something like this:

    Host foo
    HostName bar.example.com
    User baz

With this, you can alreadt leverage standard `ssh` connections:

    ssh foo

... instead of 

    ssh baz@bar.example.com

Next, generate a file `~/.autossh_rc` with the following format:

    foo 12345

... with the first entry on the line representing your `Host` in `~/.ssh/config` and the second item on the line being the port over which to keep the autossh connection alive.

Now you can permanently connect using:

    assh foo

... with the connection kept alive across network switches and computer shutdowns.


= ATTRIBUTES

* hosts: HashRef holding the values HOSTNAME => AUTOSSH_PORT

* ports: HashRef holding the values HOSTNAME => {USER => USERNAME, HOST => HOSTNAME}

* ssh_config_file: The path to the ssh config file. Default: `~/.ssh/config`

* ports_config_file: The path to the ports config (this is what I have chosen): `~/.autossh_rc`

= SEE ALSO

* autossh: <http://www.harding.motd.ca/autossh/>

=end wikidoc
