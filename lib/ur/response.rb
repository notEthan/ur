require 'ur' unless Object.const_defined?(:Ur)

class Ur
  class Response
    include RequestAndResponse
    include SubUr
  end
end
