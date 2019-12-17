proc { |p| $:.unshift(p) unless $:.any? { |lp| File.expand_path(lp) == p } }.call(File.expand_path('../lib', File.dirname(__FILE__)))

require 'simplecov'
require 'byebug'

# NO EXPECTATIONS
ENV["MT_NO_EXPECTATIONS"] = ''

require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class UrSpec < Minitest::Spec
  if ENV['UR_TEST_ALPHA']
    # :nocov:
    define_singleton_method(:test_order) { :alpha }
    # :nocov:
  end

  def assert_json_equal(exp, act, *a)
    assert_equal(JSI::Typelike.as_json(exp), JSI::Typelike.as_json(act), *a)
  end
end

# register this to be the base class for specs instead of Minitest::Spec
Minitest::Spec.register_spec_type(//, UrSpec)

require 'ur'
