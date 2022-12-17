lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ur/version"

Gem::Specification.new do |spec|
  spec.name          = "ur"
  spec.version       = UR_VERSION
  spec.authors       = ["Ethan"]
  spec.email         = ["ethan.ur@unth.net"]

  spec.summary       = 'ur: unified request representation'
  spec.description   = 'ur provides a unified representation of a request and response. it can be interpreted from rack, faraday, or potentially other sources, and provides a consistent interface to access the attributes inherent to the request and additional useful parsers and computation from the request.'
  spec.homepage      = "https://github.com/notEthan/ur"
  spec.license       = "LGPL-3.0"

  spec.files = [
    'LICENSE.md',
    'CHANGELOG.md',
    'README.md',
    '.yardopts',
    'resources/ur.schema.yml',
    'ur.gemspec',
    *Dir['lib/**/*'],
  ].reject { |f| File.lstat(f).ftype == 'directory' }

  spec.require_paths = ["lib"]

  spec.add_dependency "jsi", "~> 0.6.0"
  spec.add_dependency "addressable", "~> 2.0"
end
