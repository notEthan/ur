require_relative 'test_helper'

describe 'Ur' do
  it 'has a valid schema' do
    Ur.schema.validate_schema!
  end

  it 'initializes' do
    Ur.new({})
  end

  it 'would prefer not to initialize' do
    assert_raises(TypeError) { Ur.new("hello!") }
  end
end
