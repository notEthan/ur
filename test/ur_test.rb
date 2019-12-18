require_relative 'test_helper'
require 'faraday'
require 'active_support/tagged_logging'

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
        assert_instance_of(Time, ur.metadata.began_at)
        assert_nil(ur.metadata.duration)
        assert(ur.validate)
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
        assert(ur.validate)
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
          assert_instance_of(Time, ur.metadata.began_at)
          assert_nil(ur.metadata.duration)
          assert(ur.validate)
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
          assert(ur.validate)
        end,
      )
      builder.use(Faraday::Adapter::Rack, rack_app)
    end
    res = faraday_conn.get('/', nil, {'Foo' => 'bar'})
    assert(called_rack_before_request)
    assert(called_rack_after_response)
    assert(called_faraday_before_request)
    assert(called_faraday_after_response)
    assert_equal(200, res.status)
    assert_equal('ᚒ', res.body)
  end
end
