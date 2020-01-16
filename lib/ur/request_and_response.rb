# frozen_string_literal: true

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

    def content_type
      headers.each do |k, v|
        return ContentType.new(v) if k =~ /\Acontent[-_]type\z/i
      end
      nil
    end

    def media_type
      content_type ? content_type.media_type : nil
    end

    # @return [Boolean] is our content type JSON?
    def json?
      content_type && content_type.json?
    end

    # @return [Boolean] is our content type XML?
    def xml?
      content_type && content_type.json?
    end

    # @return [Boolean] is our content type x-www-form-urlencoded?
    def form_urlencoded?
      content_type && content_type.form_urlencoded?
    end
  end
end
