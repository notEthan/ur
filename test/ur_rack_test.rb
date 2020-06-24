require_relative 'test_helper'
require 'rack'

describe 'Ur rack integration' do
  it 'builds from a rack env' do
    env = Rack::MockRequest.env_for('https://ur.unth.net/', {'HTTP_FOO' => 'bar'})
    ur = Ur.from_rack_request(env)
    assert_equal('inbound', ur.bound)
    assert_equal('GET', ur.request['method'])
    assert_equal('bar', ur.request.headers['foo'])
    assert_equal('https://ur.unth.net/', ur.request.uri)
    assert(ur.response.empty?)
    assert(ur.jsi_valid?)
  end
  it 'builds from a rack request' do
    env = Rack::Request.new(Rack::MockRequest.env_for('https://ur.unth.net/', {'HTTP_FOO' => 'bar'}))
    ur = Ur.from_rack_request(env)
    assert_equal('inbound', ur.bound)
    assert_equal('GET', ur.request['method'])
    assert_equal('bar', ur.request.headers['foo'])
    assert_equal('https://ur.unth.net/', ur.request.uri)
    assert(ur.response.empty?)
    assert(ur.jsi_valid?)
  end
end
