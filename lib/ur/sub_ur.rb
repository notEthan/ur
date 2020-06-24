# frozen_string_literal: true

require 'ur' unless Object.const_defined?(:Ur)

module Ur
  module SubUr
    def ur
      jsi_parent_nodes.detect { |p| p.is_a?(::Ur) }
    end
  end
end
