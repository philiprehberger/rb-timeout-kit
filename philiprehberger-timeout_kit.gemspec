# frozen_string_literal: true

require_relative "lib/philiprehberger/timeout_kit/version"

Gem::Specification.new do |spec|
  spec.name = "philiprehberger-timeout_kit"
  spec.version = Philiprehberger::TimeoutKit::VERSION
  spec.authors = ["Philip Rehberger"]
  spec.email = ["me@philiprehberger.com"]

  spec.summary = "Safe timeout patterns without Thread.raise"
  spec.description = "A cooperative timeout library providing deadline and timeout patterns that " \
                     "avoid Thread.raise, with nested deadline support and explicit cancellation checks."
  spec.homepage = "https://github.com/philiprehberger/rb-timeout-kit"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]
end
