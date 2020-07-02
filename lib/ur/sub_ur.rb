# frozen_string_literal: true

require 'ur' unless Object.const_defined?(:Ur)

module Ur
  module SubUr
    def ur
      parent_jsis.detect { |p| p.is_a?(::Ur) }
    end
  end
end
