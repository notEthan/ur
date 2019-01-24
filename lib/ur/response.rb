require 'ur' unless Object.const_defined?(:Ur)

class Ur
  class Response
    include RequestAndResponse
    include SubUr

    def success?
      (200..299).include?(status)
    end

    def client_error?
      (400..499).include?(status)
    end

    def server_error?
      (500..599).include?(status)
    end
  end
end
