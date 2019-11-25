# v0.0.3
- bump JSI version

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
