
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ur/version"

Gem::Specification.new do |spec|
  spec.name          = "ur"
  spec.version       = UR_VERSION
  spec.authors       = ["Ethan"]
  spec.email         = ["ethan@unth"]

  spec.summary       = 'ur: unified request representation'
  spec.description   = 'ur provides a unified representation of a request and response. it can be interpreted from rack, faraday, or potentially other sources, and provides a consistent interface to access the attributes inherent to the request and additional useful parsers and computation from the request.'
  spec.homepage      = "https://github.com/notEthan/ur"
  spec.license       = "MIT"

  ignore_files = %w(.gitignore .travis.yml Gemfile test)
  ignore_files_re = %r{\A(#{ignore_files.map { |f| Regexp.escape(f) }.join('|')})(/|\z)}
  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  Dir.chdir(File.expand_path('..', __FILE__)) do
    spec.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(ignore_files_re) }
    spec.test_files  = `git ls-files -z test`.split("\x0") + [
      '.simplecov',
    ]
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "jsi", "~> 0.0.3"
  spec.add_dependency "addressable", "~> 2.0"
  spec.add_development_dependency "rack"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "faraday"
  spec.add_development_dependency "faraday_middleware"
  spec.add_development_dependency "activesupport"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "simplecov"
end
