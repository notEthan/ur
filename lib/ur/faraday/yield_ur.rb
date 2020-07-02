# frozen_string_literal: true

module Ur
  module Faraday
    # Faraday middleware which yields an Ur to the given block
    class YieldUr < ::Ur::FaradayMiddleware
      def initialize(app, **options, &block)
        raise(ArgumentError, "no block given to yield ur") unless block
        super(app, options.merge(after_response: block))
      end
    end
  end
end
