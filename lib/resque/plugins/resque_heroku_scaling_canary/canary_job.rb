require "resque/plugins/resque_heroku_scaling_canary/config"

module Resque
  module Plugins
    module ScalingCanary
      class CanaryJob

        @queue = "~scaling-canary"

        def self.perform(timeout)
          before = self.non_canary_jobs_pending
          Kernel.sleep Config.polling_interval
          after = self.non_canary_jobs_pending
          if before == after and before == 0
            Config.heroku_client.set_workers(Config.heroku_app, 0)
          else
            Resque.enqueue(self, timeout)
          end
        end

        def self.canary_jobs_pending
          Resque.size(@queue)
        end

        def self.non_canary_jobs_pending
          waiting = Resque.queues.inject(0){ |accum, item| accum += Resque.size(item) unless item == @queue }
          being_processed = Resque.workers.find_all{ |w| w.processing["queue"] and w.processing["queue"] != @queue }.count
          waiting + being_processed
        end

      end
    end
  end
end
