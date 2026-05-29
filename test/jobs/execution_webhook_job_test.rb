require "test_helper"

class ExecutionWebhookJobTest < ActiveJob::TestCase
  setup do
    @alice = accounts(:alice)
    @bob = accounts(:bob)
    @data_analysis = skills(:data_analysis)
    @execution = executions(:execution_one)
  end

  test "fires webhook on execution completion" do
    stub = stub_request(:post, "https://example.com/webhook")
      .with(body: hash_including(event: "execution.completed"))
      .to_return(status: 200)

    @data_analysis.update!(webhook_url: "https://example.com/webhook")

    execution = Execution.create!(
      skill: @data_analysis,
      buyer: @bob,
      status: "completed",
      timestamp: Time.current
    )

    perform_enqueued_jobs do
      ExecutionWebhookJob.perform_later(execution.id)
    end

    assert_requested stub, times: 1
  end

  test "fires webhook on execution failure" do
    stub = stub_request(:post, "https://example.com/webhook")
      .with(body: hash_including(event: "execution.failed"))
      .to_return(status: 200)

    @data_analysis.update!(webhook_url: "https://example.com/webhook")
    @execution.update!(status: "failed")

    perform_enqueued_jobs do
      ExecutionWebhookJob.perform_later(@execution.id)
    end

    assert_requested stub, times: 1
  end

  test "skips webhook when URL is nil" do
    @data_analysis.update!(webhook_url: nil)

    perform_enqueued_jobs do
      ExecutionWebhookJob.perform_later(@execution.id)
    end
    # No HTTP request should have been made — no stubs to assert
  end

  test "retries on 5xx response" do
    stub = stub_request(:post, "https://example.com/webhook")
      .to_return(status: 500)

    @data_analysis.update!(webhook_url: "https://example.com/webhook")
    execution = Execution.create!(
      skill: @data_analysis,
      buyer: @bob,
      status: "completed",
      timestamp: Time.current
    )

    assert_raises ExecutionWebhookJob::ServerError do
      ExecutionWebhookJob.new.perform(execution.id)
    end

    assert_requested stub, times: 1
  end

  test "discards on 4xx response without retry" do
    stub = stub_request(:post, "https://example.com/webhook")
      .to_return(status: 404)

    @data_analysis.update!(webhook_url: "https://example.com/webhook")
    execution = Execution.create!(
      skill: @data_analysis,
      buyer: @bob,
      status: "completed",
      timestamp: Time.current
    )

    # 4xx should be discarded (not retried), so perform should not raise
    perform_enqueued_jobs do
      ExecutionWebhookJob.perform_later(execution.id)
    end

    assert_requested stub, times: 1
  end
end
