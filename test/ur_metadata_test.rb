require_relative 'test_helper'

describe 'Ur metadata' do
  it 'sets duration from began_at' do
    ur = Ur.new
    ur.metadata.began_at = Time.now
    ur.metadata.finish!
    assert_instance_of(Float, ur.metadata.duration)
    assert_operator(ur.metadata.duration, :>, 0)
  end
end
