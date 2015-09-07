package Session;
use JSON;
use strict;

my $json = JSON->new->utf8;

sub new {
    my ($class) = @_;
    my $obj = {
        clients => {},
        ice => {},
        status => 'open',
    };
    return bless $obj, $class;
}

sub add_ice {
    my ($self, $c, $ice) = @_;
    if (!defined $self->{ice}->{$c}) {
        $self->{ice}->{$c} = [];
    }
    push @{$self->{ice}->{$c}}, $ice;
    $self->send_to_peer($c, 'ice', $ice);
}

sub get_ice {
    my ($self, $c) = @_;

    for my $k (keys %{$self->{clients}}) {
        my $oc = $self->{clients}->{$k};
        if ($c != $oc) {
            for my $ice (@{$self->{ice}->{$oc}}) {
                $self->send_to($c, 'ice', $ice);
            }
        }
    }
}

sub add_peer {
    my ($self, $c) = @_;
    if (keys %{$self->{clients}} == 2) {
        warn "Attempted to add a third client to session";
        return;
    }
    $self->{clients}->{$c} = $c;
}

sub remove_peer {
    my ($self, $c) = @_;
    delete $self->{clients}->{$c};
    if (keys %{$self->{clients}} == 0) {
        return 1;
    }
    return 0;
}

sub set_status {
    my ($self, $status) = @_;
    $self->{status} = $status;
}

sub send_to_peer {
    my ($self, $c, $type, $payload) = @_;
    if (keys %{$self->{clients}} < 2) {
        return;
    }
    for my $k (keys %{$self->{clients}}) {
        my $oc = $self->{clients}->{$k};
        if ($c != $oc) {
            $oc->send($json->encode([$type, $payload]));
        }
    }
}

sub send_to {
    my ($self, $c, $type, $payload) = @_;
    $c->send($json->encode([$type, $payload]));
}

1;
