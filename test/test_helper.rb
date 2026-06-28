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
require "pathname"
require "bcrypt"

module ActiveSupport
  class TestCase
    TEST_API_KEYS = {
      alice: "test_alice_api_key_123",
      bob: "test_bob_api_key_456",
      charlie: "test_charlie_api_key_789",
      suspended_user: "test_suspended_api_key_000",
      disabled_user: "test_disabled_api_key_111"
    }.freeze

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
      { "X-API-Key" => plaintext_api_key_for(account), "Content-Type" => "application/json" }.merge(other_headers)
    end

    # Shorthand: merge auth headers into any existing headers hash.
    def authenticated_headers(account, headers = {})
      headers.merge("X-API-Key" => plaintext_api_key_for(account))
    end

    def plaintext_api_key_for(account)
      TEST_API_KEYS.fetch(account.name.downcase.to_sym)
    end

    def create_verified_skill_listing(name:, slug:, author:, price:, description:, version: "1.0.0", entrypoint: "pricing_review.evaluate", file_bundle: [])
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
        "entrypoint" => entrypoint,
        "input_schema" => {
          "type" => "object",
          "required" => [ "items" ],
          "properties" => {
            "items" => { "type" => "array" }
          }
        },
        "output_schema" => {
          "type" => "object"
        },
        "files" => file_bundle
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

    def vendored_alms_bundle_root
      Rails.root.join("test", "fixtures", "alms_bundle")
    end

    def read_vendored_alms_file(relative_path)
      path = vendored_alms_bundle_root.join(relative_path)
      raise "Expected vendored ALMS file at #{path}" unless path.exist?

      path.read
    end

    def build_alms_file_bundle(*relative_paths)
      relative_paths.map do |relative_path|
        {
          "path" => relative_path,
          "media_type" => media_type_for(relative_path),
          "content" => read_vendored_alms_file(relative_path)
        }
      end
    end

    def media_type_for(relative_path)
      extension = Pathname(relative_path).extname

      case extension
      when ".md"
        "text/markdown"
      when ".py"
        "text/x-python"
      else
        "text/plain"
      end
    end
  end
end
