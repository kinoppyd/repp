
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "repp/version"

Gem::Specification.new do |spec|
  spec.name          = "repp"
  spec.version       = Repp::VERSION
  spec.authors       = ["kinoppyd"]
  spec.email         = ["WhoIsDissolvedGirl+github@gmail.com"]

  spec.summary       = %q{Repp is a chat service interface}
  spec.description   = %q{Repp is a chat service interface}
  spec.homepage      = "https://github.com/kinoppyd/repp"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "eventmachine", "~> 1.2"
  spec.add_dependency "slack-ruby-client", "~> 0.11"
  spec.add_dependency "faye-websocket", "~> 0.10"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
