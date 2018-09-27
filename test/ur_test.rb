require_relative 'test_helper'

describe 'Ur' do
  it 'initializes' do
    Ur.new({})
  end

  it 'would prefer not to initialize' do
    assert_raises(TypeError) { Ur.new("hello!") }
  end
end
