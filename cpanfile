requires 'parent', 0;
requires 'Ryu', 0;
requires 'IO::Async', '>= 0.60';

recommends 'Heap', 0;
recommends 'IO::Async::Loop::Epoll', 0;

on 'test' => sub {
	requires 'Test::More', '>= 0.98';
	requires 'Test::Fatal', '>= 0.010';
	requires 'Test::Refcount', '>= 0.07';
};

