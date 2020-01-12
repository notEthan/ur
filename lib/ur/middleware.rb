# frozen_string_literal: true

require 'ur' unless Object.const_defined?(:Ur)

module Ur
  module Middleware
    def initialize(app, options = {})
      @app = app
      @options = options
    end
    attr_reader :app
    attr_reader :options

    def begin_request(ur)
      ur.metadata.begin!
    end

    def finish_request(ur)
      ur.logger_tags(@options[:logger])
      ur.metadata.finish!
    end

    def invoke_callback(name, *a, &b)
      if @options[name]
        @options[name].call(*a, &b)
      end
    end
  end

  class FaradayMiddleware < ::Faraday::Middleware
    include Ur::Middleware
    def call(request_env)
      ur = Ur.from_faraday_request(request_env, @options.select { |k, _| [:schemas].include?(k) })
      invoke_callback(:before_request, ur)
      begin_request(ur)
      ur.faraday_on_complete(@app, request_env) do |response_env|
        finish_request(ur)
        invoke_callback(:after_response, ur)
      end
    end
  end

  class RackMiddleware
    include Ur::Middleware
    def call(env)
      ur = Ur.from_rack_request(env, @options.select { |k, _| [:schemas].include?(k) })
      invoke_callback(:before_request, ur)
      begin_request(ur)
      ur.with_rack_response(@app, env) do
        finish_request(ur)
        invoke_callback(:after_response, ur)
      end
    end
  end
end
