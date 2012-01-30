resque-heroku-scaling-canary
============================

This gem defines a Resque plugin that allows you to automatically
scale up the number of workers running on Heroku and then automatically scale them down once
no work is left to do. To use, extend the module from your job:

    class MyJob
      extend Resque::Plugins::ScalingCanary
      
      def self.minimum_workers_needed
        10
      end

      def self.perform
        ...      
      end
    end

Defining `minimum_workers_needed` like we did above is optional, but if you don't define it, it
defaults to 1. ScalingCanary makes sure that when your job is enqueued there are at least this
many workers working to service it.

Next, define the environment variables HEROKU_USER, HEROKU_PASSWORD, and HEROKU_APP with your
heroku credentials and app name:

    $ heroku config:add HEROKU_USER=aaron@art.sy
    $ heroku config:add HEROKU_PASSWORD=5u93r53cr37
    $ heroku config:add HEROKU_APP=awesome-app

When you enqueue your job, you'll see a new queue called "~scaling-canary" created with a single
job in it. This job is the canary - its queue name is lexicographically after any other queue
names you have, so it'll get processed last. When it runs, it looks around to see if any other
jobs are being worked on or are awaiting workers on any queues. If any are, it requeues itself,
but if everything's finished, it shuts down all workers.

There are a few other gems that allow you to automatically scale up the Heroku workers you 
use in response to your Resque load and then kill those workers automatically when 
the work is done: [resque-heroku-autoscaler](https://github.com/ajmurmann/resque-heroku-autoscaler)
and [hirefire](https://github.com/meskyanichi/hirefire) are two notable examples. This gem is
takes a dumber but more easily auditable approach than either of the above alternatives that's
better suited to systems running a largish set of batch jobs that might spawn other Resque jobs.
In particular, this gem is meant to work well with jobs using 
[resque-multi-step](https://github.com/pezra/resque-multi-step), which enqueues finalization
jobs from within Resque tasks in a way that sometimes confuses other auto-scaling gems.

This plugin works with Resque version 1.9 and above.

Installation:
-------------

    gem install resque_heroku_scaling_canary

Configuration:
--------------

You can configure the following parameters:

   * `heroku_user`: defaults to the value of the environment variable HEROKU_USER
   * `heroku_password`: defaults to the value of the environment variable HEROKU_PASSWORD
   * `heroku_app`: defaults to the value of the environment variable HEROKU_APP
   * `polling_interval`: the polling interval, in seconds, that the canary should wait
      between checking the outstanding Resque jobs and working Resque workers. To be
      safe, the canary checks these values twice, waiting for `polling_interval` seconds
      in between, before shutting all workers down.
   * `disable_scaling_if`: called with a block, will evaluate the block and disable
      scaling entirely if it evaluates to `true`.

These values are easiest to configure in an initializer, for example, create the
file config/initializers/resque_heroku_scaling_canary.rb and put something like the
following in the file:

    require 'resque_heroku_scaling_canary'

    Resque::Plugins::ScalingCanary.config do |config|
      config.heroku_app = "myapp"
      config.polling_interval = 3
      config.disable_scaling_if{ Rails.env == 'development' }
    end