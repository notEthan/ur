# v0.2.2

- Ur::Weblink
- JSI v0.7.0
- Ruby 3

# v0.2.1

- JSI v0.6.0

# v0.2.0

- Ur uses JSI schema modules instead of classes

# v0.1.1
- minor fixes

# v0.1.0
- rename processing to metadata
- Ur::ContentType

# v0.0.4
- bump JSI v0.2.0

# v0.0.3
- bump JSI v0.1.0

# v0.0.2

- module SubUr common to Ur::Request, Response, Processing
- Ur methods prefixed with sub-ur names delegate, e.g. Ur#request_uri delegates to ur.request.uri
- Ur::Response#success?, #client_error?, #server_error?
- Ur::Request and Ur::Response content_type attributes and media_type
- Ur::Faraday::YieldUr middleware
- bugfixes and refactoring

# v0.0.1

- Ur, Ur::Request, Ur::Response, Ur::Processing
- Rack and Faraday integration
- Ur::Middleware, FaradayMiddleware, RackMiddleware
