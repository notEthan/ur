require 'ur' unless Object.const_defined?(:Ur)

class Ur
  module Middleware
    def initialize(app, options = {})
      @app = app
      @options = options
    end
    attr_reader :app
    attr_reader :options

    def invoke_callback(name, *a, &b)
      if @options[name]
        @options[name].call(*a, &b)
      end
    end
  end

  class FaradayMiddleware < ::Faraday::Middleware
    include Ur::Middleware
    def call(request_env)
      ur = Ur.from_faraday_request(request_env)
      invoke_callback(:before_request, ur)
      ur.logger = options[:logger] if options[:logger]
      ur.faraday_on_complete(@app, request_env) do |response_env|
        invoke_callback(:after_response, ur)
      end
    end
  end

  class RackMiddleware
    include Ur::Middleware
    def call(env)
      ur = Ur.from_rack_request(env)
      invoke_callback(:before_request, ur)
      ur.logger = options[:logger] if options[:logger]
      ur.with_rack_response(@app, env) do
        invoke_callback(:after_response, ur)
      end
    end
  end
end
