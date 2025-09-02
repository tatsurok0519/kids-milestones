# frozen_string_literal: true
module SqlProfiler
  extend ActiveSupport::Concern

  included do
    around_action :profile_sql!, if: :sql_profiler_enabled?
  end

  private

  def sql_profiler_enabled?
    Rails.env.development? || ENV["SQL_PROFILE"] == "1"
  end

  def profile_sql!
    count = 0
    sql_ms = 0.0

    sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
      # SCHEMA / TRANSACTION はノイズなので除外
      next if payload[:name] == "SCHEMA" || payload[:name] == "TRANSACTION"
      count  += 1
      sql_ms += payload[:duration].to_f
    end

    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
  ensure
    ActiveSupport::Notifications.unsubscribe(sub) if sub
    total_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000.0
    Rails.logger.info format("[SQL-PROFILE] queries=%d sql=%.1fms total=%.1fms path=%s",
                             count, sql_ms, total_ms, request.fullpath)
    # 簡易にヘッダでも確認できるように
    response.set_header("X-SQL-Queries", count.to_s) rescue nil
    response.set_header("X-SQL-Time",    format("%.1fms", sql_ms)) rescue nil
  end
end