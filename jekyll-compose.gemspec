# frozen_string_literal: true

require_relative "lib/jekyll-compose/version"

Gem::Specification.new do |spec|
  spec.name = "jekyll-compose"
  spec.version = Jekyll::Compose::VERSION
  spec.authors = ["Parker Moore"]
  spec.email = ["parkrmoore@gmail.com"]
  spec.summary = "Streamline your writing in Jekyll with these commands."
  spec.description = "Streamline your writing in Jekyll with these commands."
  spec.homepage = "https://github.com/jekyll/jekyll-compose"
  spec.license = "MIT"

  spec.files = `git ls-files -z`.split("\x0").grep(%r{^lib/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7.7"

  spec.add_dependency "jekyll", "~> 4.3", ">= 4.3.1"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 13.0", ">= 13.0.6"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "standard", "~> 0.5"
end
