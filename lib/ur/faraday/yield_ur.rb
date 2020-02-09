# frozen_string_literal: true

class Ur
  module Faraday
    # Faraday middleware which yields an Ur to the given block
    class YieldUr < ::Ur::FaradayMiddleware
      def initialize(app, options = {}, &block)
        raise(ArgumentError, "no block given to yield ur") unless block
        raise(TypeError, "options must be a Hash") unless options.respond_to?(:to_hash)
        @app = app
        @options = options
        @yield_to = block
      end

      def call(request_env)
        ur = (@options[:ur_class] || Ur).from_faraday_request(request_env)
        begin_request(ur)
        ur.faraday_on_complete(@app, request_env) do |response_env|
          finish_request(ur)
          @yield_to.call(ur)
        end
      end
    end
  end
end
