require_relative 'test_helper'

describe 'Ur processing' do
  it 'sets duration from began_at' do
    ur = Ur.new
    ur.processing.began_at = Time.now
    ur.processing.finish!
    assert_instance_of(Float, ur.processing.duration)
    assert_operator(ur.processing.duration, :>, 0)
  end
end
