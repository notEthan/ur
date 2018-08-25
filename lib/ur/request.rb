require 'ur' unless Object.const_defined?(:Ur)

class Ur
  class Request
    include RequestAndResponse

    def addressable_uri
      uri ? Addressable::URI.parse(uri) : nil
    end
    def addressable_uri=(auri)
      self.uri = auri ? auri.normalize.to_s : nil
    end
  end
end
