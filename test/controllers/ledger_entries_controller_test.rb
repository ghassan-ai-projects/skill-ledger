require "test_helper"

class Api::V1::LedgerEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = accounts(:alice)
    @bob = accounts(:bob)
    @charlie = accounts(:charlie)
    @data_analysis = skills(:data_analysis)
  end

  test "GET /api/v1/ledger returns all ledger entries" do
    get api_v1_ledger_index_url, headers: headers_with_auth(@alice)
    assert_response :success

    body = response.parsed_body
    assert_equal 2, body["ledger_entries"].length
  end

  test "GET /api/v1/ledger includes meta with pagination info" do
    get api_v1_ledger_index_url, headers: headers_with_auth(@alice)
    assert_response :success

    meta = response.parsed_body["meta"]
    assert_equal 1, meta["current_page"]
    assert_equal 1, meta["total_pages"]
    assert_equal 2, meta["total_count"]
    assert_equal 20, meta["per_page"]
  end

  test "GET /api/v1/ledger includes from_account and to_account names" do
    get api_v1_ledger_index_url, headers: headers_with_auth(@alice)
    assert_response :success

    entry = response.parsed_body["ledger_entries"].find { |e| e["entry_type"] == "transfer" }
    assert_not_nil entry

    assert_not_nil entry["from_account"]
    assert_not_nil entry["to_account"]
    assert_equal @alice.name, entry["from_account"]["name"]
    assert_equal @bob.name, entry["to_account"]["name"]
  end

  test "GET /api/v1/ledger includes ledger entry created by skill execution" do
    post api_v1_execute_skill_url(@data_analysis),
         headers: headers_with_auth(@charlie), as: :json
    assert_response :created
    execution = Execution.last

    patch complete_api_v1_execution_url(execution), headers: headers_with_auth(@alice), as: :json
    assert_response :ok

    get api_v1_ledger_index_url, headers: headers_with_auth(@alice)
    assert_response :success
    assert_equal 3, response.parsed_body["ledger_entries"].length

    new_entry = response.parsed_body["ledger_entries"].find { |e| e["entry_type"] == "skill_execution" }
    assert_not_nil new_entry
    assert_equal @charlie.id, new_entry["from_account"]["id"]
    assert_equal @alice.id, new_entry["to_account"]["id"]
  end

  test "GET /api/v1/ledger shows correct amounts" do
    get api_v1_ledger_index_url, headers: headers_with_auth(@alice)
    assert_response :success

    alice_to_bob = response.parsed_body["ledger_entries"].find do |e|
      e["from_account"]["name"] == "Alice" && e["to_account"]["name"] == "Bob"
    end
    assert_not_nil alice_to_bob
    assert_equal "100.0", alice_to_bob["amount"]
  end

  test "GET /api/v1/ledger filters by account_id (as sender)" do
    get api_v1_ledger_index_url(account_id: @alice.id), headers: headers_with_auth(@alice)
    assert_response :success

    body = response.parsed_body
    assert_equal 1, body["ledger_entries"].length
    assert_equal @alice.id, body["ledger_entries"][0]["from_account"]["id"]
  end

  test "GET /api/v1/ledger filters by account_id (as receiver)" do
    get api_v1_ledger_index_url(account_id: @charlie.id), headers: headers_with_auth(@alice)
    assert_response :success

    body = response.parsed_body
    assert_equal 1, body["ledger_entries"].length
    assert_equal @charlie.id, body["ledger_entries"][0]["to_account"]["id"]
  end

  test "GET /api/v1/ledger returns empty when no entries match account_id filter" do
    get api_v1_ledger_index_url(account_id: 99999), headers: headers_with_auth(@alice)
    assert_response :success
    assert_equal [], response.parsed_body["ledger_entries"]
    assert_equal 0, response.parsed_body["meta"]["total_count"]
  end

  test "GET /api/v1/ledger returns empty when no entries exist" do
    LedgerEntry.delete_all

    get api_v1_ledger_index_url, headers: headers_with_auth(@alice)
    assert_response :success
    assert_equal [], response.parsed_body["ledger_entries"]
    assert_equal 0, response.parsed_body["meta"]["total_count"]
  end
end
