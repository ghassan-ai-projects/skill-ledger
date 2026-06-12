ENV["RAILS_ENV"] ||= "test"

if ENV["CI"]
  require "simplecov"
  SimpleCov.start "rails" do
    add_filter "/bin/"
    add_filter "/db/"
    add_filter "/test/"
    add_filter "/config/"
  end
end

require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

module ActiveSupport
  class TestCase
    # Respect PARALLEL_WORKERS=1 to force serial SQLite runs during local development.
    configured_workers = ENV["PARALLEL_WORKERS"]&.to_i
    parallelize(workers: configured_workers) if configured_workers && configured_workers > 1
    parallelize(workers: :number_of_processors) if configured_workers.nil?

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

    def create_verified_skill_listing(name:, slug:, author:, price:, description:, version: "1.0.0")
      skill = Skill.create!(
        name: name,
        slug: slug,
        description: description,
        author: author,
        price: price,
        listing_status: "listed"
      )

      skill_version = SkillVersion.create!(
        skill: skill,
        version: version,
        status: "draft"
      )

      manifest = {
        "name" => slug,
        "description" => description,
        "version" => version,
        "runtime" => "client",
        "entrypoint" => "pricing_review.evaluate",
        "input_schema" => {
          "type" => "object",
          "required" => [ "items" ],
          "properties" => {
            "items" => { "type" => "array" }
          }
        },
        "output_schema" => {
          "type" => "object"
        }
      }

      artifact = SkillArtifact.create!(
        skill_version: skill_version,
        artifact_type: "mcp_tool_manifest",
        manifest: manifest,
        checksum: SkillArtifactVerificationService.checksum_for_manifest(manifest)
      )

      verification = SkillArtifactVerificationService.new(skill_version: skill_version).call

      {
        skill: skill,
        version: skill_version.reload,
        artifact: artifact.reload,
        verification: verification.reload
      }
    end
  end
end
