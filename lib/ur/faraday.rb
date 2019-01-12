require 'faraday'

class Ur
  module Faraday
    autoload :YieldUr, 'ur/faraday/yield_ur'
  end
end

Faraday::Response.register_middleware(:yield_ur => proc { Ur::Faraday::YieldUr })
