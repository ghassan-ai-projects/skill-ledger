# frozen_string_literal: true

# Lograge-style request logging: one line per request with method, path, status, and duration.
Rails.application.config.after_initialize do
  ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    payload = event.payload

    # Skip health checks and noisy internal requests
    next if payload[:path]&.start_with?("/rails/")

    method    = payload[:method]&.upcase
    path      = payload[:path]
    status    = payload[:status]
    duration  = event.duration.round(2) # ms
    format    = payload[:format] || "json"
    ip        = payload[:remote_ip] || "-"
    db_duration = (payload[:db_runtime] || 0).round(2)

    Rails.logger.info format(
      "[%s] %s %s -> %s (%.1fms | db: %.1fms | fmt: %s | ip: %s)",
      Time.zone.at(event.time / 1000.0).iso8601,
      method,
      path,
      status,
      duration,
      db_duration,
      format,
      ip
    )
  end
end
