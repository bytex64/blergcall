# BlërgCall

A simple WebRTC demo.

## Dependencies

You will need [Mojolicious](http://mojolicio.us/) installed.


## Running
Then just run it like any other Mojolicious webapp.

```
$ morbo -v call.pl
```

or

```
$ ./call.pl daemon
```

It will, by default, run on port 3000 (see
[morbo](http://mojolicio.us/perldoc/morbo)
or
[Mojolicious::Command::daemon](http://mojolicio.us/perldoc/Mojolicious/Command/daemon)
docs for more info).

## Bugs

The calling end will need to be fully set up before the answering end,
or else you'll get a half-duplex connection. I need to wait for this in
the negotiation process, but haven't yet bothered.

## Misc

Includes [adapter.js](https://github.com/webrtc/adapter).
