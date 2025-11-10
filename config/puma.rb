# ===== 共通設定 =====
environment ENV.fetch('RAILS_ENV', 'development')

# スレッド数
threads_count = Integer(ENV.fetch('RAILS_MAX_THREADS', 5))
threads threads_count, threads_count

# ワーカー数（プロセス数）
workers Integer(ENV.fetch('WEB_CONCURRENCY', 2))

preload_app!  # フォーク前にアプリ読込（メモリ節約＆高速化）

# Rails/ActiveRecord の接続をワーカー起動時に貼り直す
on_worker_boot do
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
  end
end

# ===== 本番: UNIXソケットで待受（Nginx 経由） =====
if ENV['RAILS_ENV'] == 'production'
  app_dir   = File.expand_path('..', __dir__)
  shared    = File.join(app_dir, 'tmp')

  # TCPポートは使わず、UNIXソケットだけで待受
  bind "unix://#{shared}/sockets/puma.sock"

  pidfile    "#{shared}/pids/puma.pid"
  state_path "#{shared}/pids/puma.state"

  # ログ（必要に応じて変更）
  stdout_redirect "#{app_dir}/log/puma.access.log",
                  "#{app_dir}/log/puma.error.log", true

  # bin/rails restart を効かせる
  plugin :tmp_restart

# ===== 開発: 3000番ポートで待受 =====
else
  port Integer(ENV.fetch('PORT', 3000))
  pidfile 'tmp/pids/server.pid'
  plugin :tmp_restart
end