require "ur/version"

require 'jsi'

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
