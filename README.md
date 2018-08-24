# Ur ᚒ

Ur: Unified Request/Response Representation in Ruby

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
