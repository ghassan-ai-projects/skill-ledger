class ExecutionWebhookJob < ApplicationJob
  # Custom error classes must be defined before retry_on/discard_on
  class ClientError < StandardError; end
  class ServerError < StandardError; end

  queue_as :default

  # Retry on timeouts and 5xx server errors
  retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :exponentially_longer, attempts: 3
  retry_on ServerError, wait: :exponentially_longer, attempts: 3

  # Discard 4xx client errors — no point retrying
  discard_on ClientError do |job, error|
    Rails.logger.warn "[ExecutionWebhookJob] Discarded execution #{job.arguments.first} " \
                      "due to #{error.message}"
  end

  def perform(execution_id)
    execution = Execution.find(execution_id)
    skill = execution.skill

    return unless skill.webhook_url.present?

    payload = {
      event: "execution.#{execution.status}",
      execution: {
        id: execution.id,
        skill_id: skill.id,
        skill_name: skill.name,
        buyer_id: execution.buyer_id,
        status: execution.status,
        result: execution.result,
        timestamp: execution.timestamp.iso8601
      },
      skill: {
        id: skill.id,
        name: skill.name,
        author_id: skill.author_id
      }
    }

    uri = URI.parse(skill.webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = 5
    http.read_timeout = 5

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request.body = payload.to_json

    response = http.request(request)

    case response
    when Net::HTTPSuccess
      # All good
    when Net::HTTPClientError
      raise ClientError, "HTTP #{response.code}: #{response.message}"
    else
      raise ServerError, "HTTP #{response.code}: #{response.message}"
    end
  end
end
