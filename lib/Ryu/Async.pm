package Ryu::Async 0.001;
# ABSTRACT: IO::Async support for Ryu stream management
use strict;
use warnings;

use feature qw(current_sub);

=head1 NAME

Ryu::Async - use L<Ryu> with L<IO::Async>

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis.pl

=head1 DESCRIPTION

This is an L<IO::Async::Notifier> subclass for interacting with L<Ryu>.

=head1 METHODS

=cut

use parent qw(IO::Async::Notifier);

use IO::Async::Timer::Periodic;
use Ryu::Source;
use curry::weak;

=head2 from

=cut

sub from {
	use Scalar::Util qw(blessed);
	use namespace::clean qw(blessed);
	my $self = shift;

	my $src = $self->source(label => 'from');
	if(my $class = blessed $_[0]) {
		if($class->isa('IO::Async::Stream')) {
			my $stream = shift;
			$stream->configure(
				on_read => sub {
					my ($stream, $buffref, $eof) = @_;
					my $data = substr $$buffref, 0, length $$buffref, '';
					$src->emit($data);
					$src->finish if $eof && !$src->completed->is_ready;
				}
			);
			unless($stream->parent) {
				$self->add_child($stream);
				$src->completed->on_ready(sub {
					$self->remove_child($stream) if $stream->parent;
				});
			}
			return $src;
		} else {
			die "whatevs";
		}
	} elsif(my $ref = ref $_[0]) {
		if($ref eq 'ARRAY') {
			my @pending = @{$_[0]};
			(sub {
				return unless @pending;
				$src->emit(shift @pending);
				$self->loop->later(__SUB__);
			})->();
		} else {
			die "Unknown type $ref"
		}
	}

	my %args = @_;
	if(my $dir = $args{directory}) {
		opendir my $handle, $dir or die $!;
		(sub {
			if(defined(my $item = readdir $handle)) {
				$src->emit($item) unless $item eq '.' or $item eq '..';
				$self->loop->later(__SUB__);
			} else {
				closedir $handle or die $!;
				$src->finish
			}
		})->();
		return $self;
	}
	die "unknown stuff";
}

=head2 timer

=cut

sub timer {
	my ($self, %args) = @_;
	my $src = $self->source(label => 'timer');
	my $code = $src->curry::weak::emit(1);
	$self->add_child(
		my $timer = IO::Async::Timer::Periodic->new(
			%args,
			on_tick => sub {
				$code->();
			},
		)
	);
	Scalar::Util::weaken($timer);
	$src->on_ready($self->_capture_weakself(sub {
		my ($self) = @_;
		return unless $timer;
		$timer->stop if $timer->is_running;
		$self->remove_child($timer)
	}));
	$timer->start;
	$src
}

=head2 source

Returns a new L<Ryu::Source> instance.

=cut

sub source {
	my ($self, %args) = @_;
	Ryu::Source->new(
		new_future => $self->loop->curry::weak::new_future,
		%args,
	)
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Ryu>

=item * L<IO::Async>

=back

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2016. Licensed under the same terms as Perl itself.

