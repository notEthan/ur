require_relative 'test_helper'
require 'faraday'
require 'active_support'

describe 'Ur' do
  it 'has a valid schema' do
    assert(Ur.schema.jsi_valid?)
  end

  it 'initializes' do
    Ur.new_jsi({})
  end

  it 'would prefer not to initialize' do
    assert_raises(TypeError) { Ur.new("hello!") }
  end

  it 'integrates with rack and faraday middlewares' do
    rack_app = proc do |env|
      [200, {'Content-Type' => 'text/plain'}, ['ᚒ']]
    end
    client_logger = ActiveSupport::TaggedLogging.new(Logger.new(StringIO.new))
    server_logger = ActiveSupport::TaggedLogging.new(Logger.new(StringIO.new))
    called_rack_before_request = false
    called_rack_after_response = false
    called_faraday_before_request = false
    called_faraday_after_response = false
    rack_app = Ur::RackMiddleware.new(rack_app, logger: server_logger,
      before_request: -> (ur) do
        called_rack_before_request = true

        server_logger.push_tags 'ur_test_rack'

        assert_equal('inbound', ur.bound)
        assert_equal('GET', ur.request['method'])
        assert_equal('ur.unth.net', ur.request.headers['host'])
        assert_equal('bar', ur.request.headers['foo'])
        assert_equal('https://ur.unth.net/', ur.request.uri)
        assert(ur.response.empty?)
        assert_nil(ur.metadata.began_at)
        assert_nil(ur.metadata.duration)
        assert(ur.jsi_valid?)
      end,
      after_response: -> (ur) do
        called_rack_after_response = true

        server_logger.pop_tags

        assert_equal('inbound', ur.bound)
        assert_equal('GET', ur.request['method'])
        assert_equal(200, ur.response.status)
        assert_equal('text/plain', ur.response.headers['Content-Type'])
        assert_equal('ᚒ', ur.response.body)
        assert_instance_of(Time, ur.metadata.began_at)
        assert_instance_of(Float, ur.metadata.duration)
        assert_operator(ur.metadata.duration, :>, 0)
        assert_equal(['ur_test_rack'], ur.metadata.tags.to_a)
        assert(ur.jsi_valid?)
      end,
    )
    faraday_conn = ::Faraday.new('https://ur.unth.net/') do |builder|
      builder.use(Ur::FaradayMiddleware, logger: client_logger,
        before_request: -> (ur) do
          called_faraday_before_request = true

          client_logger.push_tags 'ur_test_faraday'

          assert_equal('outbound', ur.bound)
          assert_equal('get', ur.request['method'])
          assert_equal('bar', ur.request.headers['foo'])
          assert_equal('https://ur.unth.net/', ur.request.uri)
          assert_equal(Addressable::URI.parse('https://ur.unth.net/'), ur.request.addressable_uri)
          assert(ur.response.empty?)
          assert_nil(ur.metadata.began_at)
          assert_nil(ur.metadata.duration)
          assert(ur.jsi_valid?)
        end,
        after_response: -> (ur) do
          called_faraday_after_response = true

          client_logger.pop_tags

          assert_equal('outbound', ur.bound)
          assert_equal('get', ur.request['method'])
          assert_equal(200, ur.response.status)
          assert_equal('text/plain', ur.response.headers['Content-Type'])
          assert_equal('ᚒ', ur.response.body)
          assert_instance_of(Time, ur.metadata.began_at)
          assert_instance_of(Float, ur.metadata.duration)
          assert_operator(ur.metadata.duration, :>, 0)
          assert_equal(['ur_test_faraday'], ur.metadata.tags.to_a)
          assert(ur.jsi_valid?)
        end,
      )
      builder.adapter(:rack, rack_app)
    end
    res = faraday_conn.get('/', nil, {'Foo' => 'bar'})
    assert(called_rack_before_request)
    assert(called_rack_after_response)
    assert(called_faraday_before_request)
    assert(called_faraday_after_response)
    assert_equal(200, res.status)
    assert_equal('ᚒ', res.body)
  end

  it 'has content type and media type' do
    ur = Ur.new({
      'request' => {
        'headers' => {
          'Content-Type' => 'application/vnd.github+json; charset=utf8',
        },
      },
      'response' => {
        'headers' => {
          'Content-Type' => 'application/vnd.github+json; charset=utf8',
        },
      },
    })
    assert_instance_of(Ur::ContentType, ur.request.content_type)
    assert_instance_of(Ur::ContentType, ur.response.content_type)
    assert_equal('application/vnd.github+json; charset=utf8', ur.request.content_type)
    assert_equal('application/vnd.github+json; charset=utf8', ur.response.content_type)
    assert_equal('application/vnd.github+json', ur.request.media_type)
    assert_equal('application/vnd.github+json', ur.response.media_type)
    assert(ur.request.json?)
    assert(ur.response.json?)
    refute(ur.request.xml?)
    refute(ur.response.xml?)
    refute(ur.request.form_urlencoded?)
    refute(ur.response.form_urlencoded?)
  end
end
