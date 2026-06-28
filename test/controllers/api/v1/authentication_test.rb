require "test_helper"

class Api::V1::AuthenticationTest < ActionDispatch::IntegrationTest
  test "suspended account cannot authenticate" do
    suspended_account = accounts(:suspended_user)
    suspended_account.update_column(:last_used_at, nil)

    get api_v1_skills_url, headers: headers_with_auth(suspended_account)

    assert_response :unauthorized
    assert_equal(
      { "error" => "Invalid or missing API key", "details" => [] },
      response.parsed_body
    )
    assert_nil suspended_account.reload.last_used_at
  end

  test "disabled account cannot authenticate" do
    disabled_account = accounts(:disabled_user)
    disabled_account.update_column(:last_used_at, nil)

    get api_v1_skills_url, headers: headers_with_auth(disabled_account)

    assert_response :unauthorized
    assert_equal(
      { "error" => "Invalid or missing API key", "details" => [] },
      response.parsed_body
    )
    assert_nil disabled_account.reload.last_used_at
  end

  test "active account can authenticate" do
    active_account = accounts(:alice)

    get api_v1_skills_url, headers: headers_with_auth(active_account)

    assert_response :success
  end

  test "invalid key returns 401" do
    get api_v1_skills_url, headers: { "X-API-Key" => "not_a_real_key" }

    assert_response :unauthorized
    assert_equal(
      { "error" => "Invalid or missing API key", "details" => [] },
      response.parsed_body
    )
  end

  test "missing key returns 401" do
    get api_v1_skills_url

    assert_response :unauthorized
    assert_equal(
      { "error" => "Invalid or missing API key", "details" => [] },
      response.parsed_body
    )
  end
end
