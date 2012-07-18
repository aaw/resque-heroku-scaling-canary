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
            Config.heroku_client.ps_scale(Config.heroku_app, :type => "worker", :qty => 0)
          else
            Resque.enqueue(self, timeout)
          end
        end

        def self.canary_jobs_outstanding
          Resque.size(@queue) + Resque.workers.find_all{ |w| w.processing["queue"] == @queue }.count
        end

        def self.non_canary_jobs_pending
          waiting = Resque.queues.reject{ |q| q == @queue}.inject(0){ |accum, item| accum += Resque.size(item) }
          being_processed = Resque.workers.find_all{ |w| w.processing["queue"] and w.processing["queue"] != @queue }.count
          waiting + being_processed
        end

      end
    end
  end
end
