module Resque
  module Plugins
    module ScalingCanary
      module Config
        extend self

        @disable_scaling_if = lambda { Rails.env == 'test' }
        def disable_scaling_if(&block)
          @disable_scaling_if = block
        end

        def scaling_disabled?
          @disable_scaling_if.call
        end

        attr_writer :heroku_user
        def heroku_user
          @heroku_user ||= ENV['HEROKU_USER']
        end

        attr_writer :heroku_pass
        def heroku_pass
          @heroku_pass ||= ENV['HEROKU_PASS']
        end

        attr_writer :heroku_app
        def heroku_app
          @heroku_app ||= ENV['HEROKU_APP']
        end

        attr_writer :polling_interval
        def polling_interval
          @polling_interval ||= 5000 
        end

        def heroku_client
          @@heroku_client ||= Heroku::Client.new(Config.heroku_user, Config.heroku_pass)
        end

      end
    end
  end
end
