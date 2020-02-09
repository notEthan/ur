# frozen_string_literal: true

require 'ur' unless Object.const_defined?(:Ur)

class Ur
  module SubUr
    def ur
      parents.detect { |p| p.is_a?(::Ur) }
    end
  end
end
