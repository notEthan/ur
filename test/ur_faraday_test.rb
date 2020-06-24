require_relative 'test_helper'
require 'faraday'
require 'faraday_middleware'

describe 'Ur faraday integration' do
  it 'integrates, basic usage' do
    ur = nil
    faraday_conn = ::Faraday.new('https://ur.unth.net/') do |builder|
      builder.use(Ur::FaradayMiddleware,
        after_response: -> (ur_) { ur = ur_ },
      )
      builder.adapter(:rack, -> (env) { [200, {'Content-Type' => 'text/plain'}, ['ᚒ']] })
    end
    res = faraday_conn.get('/')
    assert_equal('ᚒ', res.body)
    assert_kind_of(Ur, ur)
    assert_equal('get', ur.request['method'])
    assert_equal('text/plain', ur.response.headers['Content-Type'])
    assert_equal('ᚒ', ur.response.body)
    assert(ur.jsi_valid?)
  end
  it 'integrates, IO body' do
    ur = nil
    faraday_conn = ::Faraday.new('https://ur.unth.net/') do |builder|
      builder.use(Ur::FaradayMiddleware,
        after_response: -> (ur_) { ur = ur_ },
      )
      builder.adapter(:rack, -> (env) { [200, {'Content-Type' => 'text/plain'}, ['☺']] })
    end
    res = faraday_conn.post('/', StringIO.new('hello!'))
    assert_equal('☺', res.body)
    assert_kind_of(Ur, ur)
    assert_equal('post', ur.request['method'])
    assert_equal('hello!', ur.request.body)
    assert_equal('text/plain', ur.response.headers['Content-Type'])
    assert_equal('☺', ur.response.body)
    assert(ur.jsi_valid?)
  end
  it 'integrates, faraday middleware munges the json bodies but uses preserve_raw' do
    ur = nil
    faraday_conn = ::Faraday.new('https://ur.unth.net/') do |builder|
      builder.request :json
      builder.use(Ur::FaradayMiddleware,
        after_response: -> (ur_) { ur = ur_ },
      )
      builder.response :json, preserve_raw: true
      builder.adapter(:rack, -> (env) { [200, {'Content-Type' => 'application/json'}, ['{}']] })
    end
    res = faraday_conn.post('/', {'a' => 'b'})
    assert_equal({}, res.body)
    assert_kind_of(Ur, ur)
    assert_equal('post', ur.request['method'])
    assert_equal('{"a":"b"}', ur.request.body)
    assert_equal('application/json', ur.response.headers['Content-Type'])
    assert_equal('{}', ur.response.body)
    assert(ur.jsi_valid?)
  end
  it 'integrates, faraday middleware munges the json bodies and does not preserve_raw' do
    ur = nil
    faraday_conn = ::Faraday.new('https://ur.unth.net/') do |builder|
      builder.use(Ur::FaradayMiddleware,
        after_response: -> (ur_) { ur = ur_ },
      )
      builder.request :json
      builder.response :json
      builder.adapter(:rack, -> (env) { [200, {'Content-Type' => 'application/json'}, ['{}']] })
    end
    res = faraday_conn.post('/', {'a' => 'b'})
    assert_equal({}, res.body)
    assert_kind_of(Ur, ur)
    assert_equal('post', ur.request['method'])
    assert_nil(ur.request.body) # no good
    assert_json_equal({"a" => "b"}, ur.request['body_parsed']) # best we get here
    assert_equal('application/json', ur.response.headers['Content-Type'])
    assert_nil(ur.response.body) # no good
    assert_json_equal({}, ur.response['body_parsed']) # best we get here
    assert(ur.jsi_valid?)
  end
end
