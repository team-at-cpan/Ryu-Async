package Ryu::Async::Server;

use strict;
use warnings;

# VERSION

sub new { bless { @_[1..$#_] }, $_[0] }

sub port { shift->{port} }
sub incoming { shift->{incoming} }
sub outgoing { shift->{outgoing} }

1;

