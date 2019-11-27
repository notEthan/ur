require "ur/version"

require 'jsi'
require 'time'
require 'addressable/uri'

Ur = JSI.class_for_schema({
  id: 'https://schemas.ur.unth.net/ur',
  type: 'object',
  properties: {
    bound: {
      type: 'string',
      description: %q([rfc2616] Inbound and outbound refer to the request and response paths for messages: "inbound" means "traveling toward the origin server", and "outbound" means "traveling toward the user agent"),
      enum: ['inbound', 'outbound'],
    },
    request: {
      type: 'object',
      properties: {
        method: {type: 'string', description: 'HTTP ', example: 'POST'},
        uri: {type: 'string', example: 'https://example.com/foo?bar=baz'},
        headers: {type: 'object'},
        body: {type: 'string'},
      },
    },
    response: {
      type: 'object',
      properties: {
        status: {type: 'integer', example: 200},
        headers: {type: 'object'},
        body: {type: 'string'},
      },
    },
    processing: {
      type: 'object',
      properties: {
        began_at_s: {type: 'string'},
        duration: {type: 'number'},
        tags: {type: 'array', items: {type: 'string'}}
      },
    },
  },
})
class Ur
  VERSION = UR_VERSION

  autoload :SubUr, 'ur/sub_ur'
  autoload :RequestAndResponse, 'ur/request_and_response'
  autoload :Middleware, 'ur/middleware'
  autoload :FaradayMiddleware, 'ur/middleware'
  autoload :RackMiddleware, 'ur/middleware'
  autoload :Faraday, 'ur/faraday'

  Request = JSI.class_for_schema(self.schema['properties']['request'])
  Response = JSI.class_for_schema(self.schema['properties']['response'])
  Processing = JSI.class_for_schema(self.schema['properties']['processing'])
  require 'ur/request'
  require 'ur/response'
  require 'ur/processing'

  autoload :ContentTypeAttrs, 'ur/content_type_attrs'

  class << self
    def from_rack_request(request_env)
      if request_env.is_a?(Rack::Request)
        rack_request = request_env
        env = request_env.env
      else
        rack_request = Rack::Request.new(request_env)
        env = request_env
      end

      new({'bound' => 'inbound'}).tap do |ur|
        ur.processing.begin!

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

    def from_faraday_request(request_env, logger: nil)
      new({'bound' => 'outbound'}).tap do |ur|
        ur.processing.begin!
        ur.request['method'] = request_env[:method].to_s
        ur.request.uri = request_env[:url].normalize.to_s
        ur.request.headers = request_env[:request_headers]
        ur.request.set_body_from_faraday(request_env)
      end
    end
  end

  def initialize(ur = {}, **opt, &b)
    super(ur, **opt, &b)
    unless instance.respond_to?(:to_hash)
      raise(TypeError, "expected hash argument. got: #{ur.pretty_inspect.chomp}")
    end
    self.request = {} if self.request.nil?
    self.response = {} if self.response.nil?
    self.processing = {} if self.processing.nil?
  end

  def logger=(logger)
    if logger && logger.formatter.respond_to?(:current_tags)
      processing.tags = logger.formatter.current_tags.dup
    end
  end

  def with_rack_response(app, env)
    status, response_headers, response_body = app.call(env)

    response.status = status
    response.headers = response_headers
    response.body = response_body.to_enum.to_a.join('')

    response_body_proxy = ::Rack::BodyProxy.new(response_body) do
      processing.finish!

      yield
    end
    [status, response_headers, response_body_proxy]
  end

  def faraday_on_complete(app, request_env, &block)
    app.call(request_env).on_complete do |response_env|
      response.status = response_env[:status]
      response.headers = response_env[:response_headers]
      response.set_body_from_faraday(response_env)
      processing.finish!

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
