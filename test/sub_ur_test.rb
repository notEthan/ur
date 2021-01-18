require_relative 'test_helper'

describe 'Ur::SubUr' do
  it 'has an ur' do
    ur = Ur.new
    assert_equal(ur, ur.request.ur)
    assert_equal(ur, ur.metadata.ur)
  end
end
