require "resque/plugins/resque_heroku_scaling_canary/config"
require "resque/plugins/resque_heroku_scaling_canary/canary_job"

module Resque
  module Plugins
    module ScalingCanary
      
      def after_enqueue_ensure_heroku_workers(*args)
        n = self.respond_to?(:minimum_workers_needed) ? self.minimum_workers_needed : 1
        return if Config.heroku_client.info(Config.heroku_app)[:workers].to_i >= n
        Config.heroku_client.set_workers(n)
        Resque.enqueue(CanaryJob) if CanaryJob.canary_jobs_pending == 0
      end

    end
  end
end
