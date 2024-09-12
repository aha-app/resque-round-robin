Resque-round-robin
==================

A plugin for Resque that implements round-robin behavior for workers.

The standard behavior for Resque workers is to pull a job off a queue,
and continue until the queue is empty.  Once empty, the worker moves
on to the next queue (if available).

For our situation, which is probably pretty rare in rails deployments,
we have multiple clients who submit jobs to resque, and we need to
keep the jobs of one customer from starving out other customers.

As we dynamically generate queues per client, the workers also try to
avoid working on the same queue at the same time.  This isn't a hard
guarantee since the code that checks and pulls the job is not atomic,
but it's good enough for our needs.


## Installation

Add this line to your application's Gemfile:

    gem 'resque-round-robin'

And then execute:

    $ bundle


## Usage

Nothing special. This gem monkey-patches things so this is automatic.

A potential TODO is to have the ability to disable the one-worker-per-queue
policy on a dynamic basis.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
