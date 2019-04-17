# Ur ᚒ

Ur: Unified Request/Response Representation in Ruby

## Properties

An ur primarily consists of a request, a response, and additional processing information.

The request consists of the request method, uri, headers, and body.

The response consists of the response status, headers, and body.

The processing information consists of the time the request began, the duration of the request, or tag strings. This is optional.

Other attributes may be present, and are ignored by this library.

## Usage with middleware

Rack middleware:

```ruby
class MyRackMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    # do things before the request

    ur = Ur.from_rack_request(env)

    # set additional properties of the ur, for example:
    ur.logger = my_logger

    rack_response = ur.with_rack_response(@app, env) do
      # do things after the response
    end
    rack_response
  end
end
```

Faraday middleware:

```ruby
class MyFaradayMiddleware < ::Faraday::Middleware
  def call(request_env)
    # do things before the request

    ur = Ur.from_faraday_request(request_env)

    # set additional properties of the ur, for example:
    ur.logger = my_logger

    ur.faraday_on_complete(@app, request_env) do |response_env|
      # do things after the response
    end
  end
end
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
