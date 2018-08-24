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

  Request = JSI.class_for_schema(self.schema['properties']['request'])
  Response = JSI.class_for_schema(self.schema['properties']['response'])
  Processing = JSI.class_for_schema(self.schema['properties']['processing'])
  require 'ur/request'
  require 'ur/response'
  require 'ur/processing'

  class << self
    def from_rack_request(request_env)
      if request_env.is_a?(Rack::Request)
        rack_request = request_env
        env = request_env.env
      else
        rack_request = Rack::Request.new(request_env)
        env = request_env
      end

      Ur.new({}).tap do |ur|
        ur.processing.begin!
        ur.bound = 'inbound'
        ur.request['method'] = rack_request.request_method
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
        ur.request.addressable_uri = Addressable::URI.new(
          :scheme => rack_request.scheme,
          :host => rack_request.host,
          :port => rack_request.port,
          :path => rack_request.path,
          :query => (rack_request.query_string unless rack_request.query_string.empty?)
        )
        env["rack.input"].rewind
        ur.request.body = env["rack.input"].read
        env["rack.input"].rewind
      end
    end
  end

  def initialize(ur = {}, *a, &b)
    super(ur, *a, &b)
    unless instance.respond_to?(:to_hash)
      raise(TypeError, "expected hash argument. got: #{ur.pretty_inspect.chomp}")
    end
    self.request = {} if self.request.nil?
    self.response = {} if self.response.nil?
    self.processing = {} if self.processing.nil?
  end
end
