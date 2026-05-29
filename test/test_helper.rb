ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Allow real HTTP connections for localhost, block everything else
    WebMock.disable_net_connect!(allow_localhost: true)

    # Returns a Hash of headers including a valid X-API-Key for the given account fixture.
    def headers_with_auth(account, other_headers = {})
      { "X-API-Key" => account.api_key, "Content-Type" => "application/json" }.merge(other_headers)
    end

    # Shorthand: merge auth headers into any existing headers hash.
    def authenticated_headers(account, headers = {})
      headers.merge("X-API-Key" => account.api_key)
    end
  end
end
