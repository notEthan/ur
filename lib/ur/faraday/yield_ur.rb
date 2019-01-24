class Ur
  module Faraday
    class YieldUr < ::Faraday::Middleware
      def initialize(app, options = {}, &block)
        @app = app
        @options = options
        @yield_to = block
      end

      def call(request_env)
        ur = Scorpio::Ur.from_faraday_request(request_env)
        ur.logger = @options[:logger]
        ur.faraday_on_complete(@app, request_env) do |response_env|
          @yield_to.call(ur)
        end
      end
    end
  end
end
