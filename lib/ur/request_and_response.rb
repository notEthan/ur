require 'ur' unless Object.const_defined?(:Ur)

class Ur
  module RequestAndResponse
    module FaradayEntity
      def set_body_from_faraday(env)
        if env[:raw_body].respond_to?(:to_str)
          self.body = env[:raw_body].to_str.dup
        elsif env[:body].respond_to?(:to_str)
          self.body = env[:body].to_str.dup
        elsif env[:body].respond_to?(:read) && env[:body].respond_to?(:rewind)
          env[:body].rewind
          self.body = env[:body].read
          env[:body].rewind
        elsif env[:body]
          # TODO not good
          self['body_parsed'] = env[:body]
        end
      end
    end
    include FaradayEntity
  end
end
