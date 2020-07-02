# frozen_string_literal: true

require "ur/version"

require 'jsi'
require 'time'
require 'addressable/uri'
require 'pathname'

UR_ROOT = Pathname.new(__FILE__).dirname.parent.expand_path
Ur = JSI::Schema.new(YAML.load_file(UR_ROOT.join('resources/ur.schema.yml'))).jsi_schema_module
module Ur
  VERSION = UR_VERSION

  autoload :SubUr, 'ur/sub_ur'
  autoload :RequestAndResponse, 'ur/request_and_response'
  autoload :Middleware, 'ur/middleware'
  autoload :FaradayMiddleware, 'ur/middleware'
  autoload :RackMiddleware, 'ur/middleware'
  autoload :Faraday, 'ur/faraday'

  Request = self.schema.properties['request'].jsi_schema_module
  Response = self.schema.properties['response'].jsi_schema_module
  Metadata = self.schema.properties['metadata'].jsi_schema_module
  require 'ur/request'
  require 'ur/response'
  require 'ur/metadata'

  autoload :ContentType, 'ur/content_type'

  class << self
    def new(instance = {}, ur_class: nil, **options)
      unless instance.respond_to?(:to_hash)
        raise(TypeError, "expected hash for ur instance. got: #{instance.pretty_inspect.chomp}")
      end
      ur_class ||= ::Ur.schema.jsi_schema_class
      ur_class.new(instance, options).tap do |ur|
        ur.request = {} if ur.request.nil?
        ur.response = {} if ur.response.nil?
        ur.metadata = {} if ur.metadata.nil?
      end
    end

    def from_rack_request(request_env)
      if request_env.is_a?(Rack::Request)
        rack_request = request_env
        env = request_env.env
      else
        rack_request = Rack::Request.new(request_env)
        env = request_env
      end

      new({'bound' => 'inbound'}).tap do |ur|
        ur.request['method'] = rack_request.request_method

        ur.request.addressable_uri = Addressable::URI.new(
          :scheme => rack_request.scheme,
          :host => rack_request.host,
          :port => rack_request.port,
          :path => rack_request.path,
          :query => (rack_request.query_string unless rack_request.query_string.empty?)
        )

        ur.request.headers = env.map do |(key, value)|
          http_match = key.match(/\AHTTP_/)
          if http_match
            name = http_match.post_match.downcase
            {name => value}
          else
            name = %w(content_type content_length).detect { |sname| sname.downcase == key.downcase }
            if name
              {name => value}
            end
          end
        end.compact.inject({}, &:update)

        env["rack.input"].rewind
        ur.request.body = env["rack.input"].read
        env["rack.input"].rewind
      end
    end

    def from_faraday_request(request_env, ur_class: nil)
      new({'bound' => 'outbound'}, ur_class: ur_class).tap do |ur|
        ur.request['method'] = request_env[:method].to_s
        ur.request.uri = request_env[:url].normalize.to_s
        ur.request.headers = request_env[:request_headers]
        ur.request.set_body_from_faraday(request_env)
      end
    end
  end

  # Ur#logger_tags applies tags from a tagged logger to this ur's metadata.
  # note: ur does not log anything and this logger is not stored.
  # @param [logger] a tagged logger
  # @return [void]
  def logger_tags(logger)
    if logger && logger.formatter.respond_to?(:current_tags)
      metadata.tags = logger.formatter.current_tags.dup
    end
  end

  def with_rack_response(app, env)
    status, response_headers, response_body = app.call(env)

    response.status = status
    response.headers = response_headers
    response.body = response_body.to_enum.to_a.join('')

    response_body_proxy = ::Rack::BodyProxy.new(response_body) do
      yield
    end
    [status, response_headers, response_body_proxy]
  end

  def faraday_on_complete(app, request_env, &block)
    app.call(request_env).on_complete do |response_env|
      response.status = response_env[:status]
      response.headers = response_env[:response_headers]
      response.set_body_from_faraday(response_env)

      yield(response_env)
    end
  end

  # define delegator sort of methods for nested property names, eg.
  #    ur.request_uri
  # this makes it easier to use Symbol#to_proc, eg urs.map(&:request_uri)
  # instead of urs.map(&:request).map(&:uri)
  schema['properties'].each do |property_name, property_schema|
    if property_schema['type'] == 'object' && property_schema['properties']
      property_schema['properties'].each_key do |property_property_name|
        # ur.request_method => ur['request']['method']
        define_method("#{property_name}_#{property_property_name}") do
          self[property_name][property_property_name]
        end
      end
    end
  end
end
