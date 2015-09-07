#!/usr/bin/env perl
use Mojolicious::Lite;
use Session;
use JSON;
use v5.10;

my ($offer_sdp, $answer_sdp);
my %sessions;
my $json = JSON->new->utf8;

get '/' => sub {
    my $c = shift;
    $c->reply->static('index.html');
};

get '/:name' => sub {
    my $c = shift;
    my $name = $c->stash('name');
    $name =~ s/[^a-zA-Z0-9]//g;
    if (!defined $sessions{$name}) {
        $sessions{$name} = Session->new;
        $c->app->log->debug("Creating session $name");
    }
    $c->reply->static('call.html');
};

websocket '/:name/switchboard' => sub {
    my $c = shift;
    my $name = $c->stash('name');
    my $session = $sessions{$name};

    $session->add_peer($c);
    $c->inactivity_timeout(300);

    $c->on(message => sub {
        my ($c, $msg) = @_;
        my $j = $json->decode($msg);
        given ($j->[0]) {
            when ('offer') {
                # MITM tampering check
                #$j->[1] =~ s/a=fingerprint:sha-256 ..:/a=fingerprint:sha-256 00:/;
                #print STDERR "SDP offer: ", $json->decode($j->[1])->{sdp}, "\n";
                if ($session->{status} ne 'open') {
                    send_to($session, $c, 'error', 'bad call state for offer');
                    warn "Bad call state for offer";
                }
                $session->{offer_sdp} = $j->[1];
                $session->send_to_peer($c, 'offer', $j->[1]);
                $session->set_status('calling');
            }
            when ('answer') {
                #print STDERR "SDP answer: ", $json->decode($j->[1])->{sdp}, "\n";
                if ($session->{status} ne 'calling') {
                    send_to($c, 'error', 'bad call state for answer');
                    warn "Bad call state for answer";
                }
                $session->{answer_sdp} = $j->[1];
                $session->send_to_peer($c, 'answer', $j->[1]);
                $session->set_status('connected');
            }
            when ('ice') {
                $session->add_ice($c, $j->[1]);
            }
            when ('ready') {
                if ($session->{status} eq 'calling') {
                    $session->send_to($c, 'offer', $session->{offer_sdp});
                    $session->get_ice($c);
                } elsif ($session->{status} eq 'open') {
                    $session->send_to($c, 'initiate');
                }
            }
            default {
                $c->app->log->warn('Unknown message type ' . $j->[0]);
            }
        }
    });

    $c->on(finish => sub {
        if ($session->remove_peer($c)) {
            $c->app->log->debug("Destroying session $name");
            delete $sessions{$name};
        }
    });
};

app->start;
