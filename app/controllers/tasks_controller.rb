class TasksController < ApplicationController
  before_action :set_breadcrumbs, only: :index

  # --- ゲスト/デモ用 軽量モデル ---
  DemoMilestone = Struct.new(:id, :title, :category, :difficulty, :min_months, :max_months, :description, :hint_text) do
    def difficulty_stars
      d = difficulty.to_i.clamp(0, 3)
      "★" * d + "☆" * (3 - d)
    end
    def age_band_labels
      mn = (min_months || 0).to_i
      mx = (max_months || 71).to_i
      bands = []
      s = (mn / 12).clamp(0, 5)
      e = (([mx - 1, mn].max) / 12).clamp(0, 5)
      (s..e).each { |i| bands << "#{i}–#{i + 1}歳" }
      bands.uniq.join(" ")
    end
  end
  private_constant :DemoMilestone

  def index
    Rails.logger.info("[tasks#index] params=#{params.to_unsafe_h.slice(:age_band, :category, :difficulty, :only_unachieved, :page)}")

    # 1) DB/テーブル存在を安全に確認
    has_ms_table = data_source_exists_safely?("milestones")
    db_count     = has_ms_table ? safe { Milestone.unscoped.count } : nil

    # 2) DB 未準備 or 0件 → だれであってもデモ表示
    if !has_ms_table || db_count.nil? || db_count.zero?
      Rails.logger.warn("[tasks#index] DEMO FALLBACK: has_table=#{has_ms_table}, count=#{db_count.inspect}")
      @demo_mode = true
      return render_demo_from_yaml
    end

    # 3) ここから通常処理（DBあり・1件以上）
    try_backfill_hints_from_yaml! # ※DBが生きていることが確認できた後で呼ぶ

    band_param = params[:age_band].presence
    if band_param == "all"
      @age_band_label = "全年齢"
      scope = Milestone.all
    else
      @age_band_index =
        if band_param.present?
          band_param.to_i.clamp(0, 5)
        elsif current_child
          current_child.age_band_index
        else
          0
        end
      @age_band_label = "#{@age_band_index}–#{@age_band_index + 1}歳"
      scope = Milestone.for_age_band(@age_band_index)
    end

    @categories      = Milestone.distinct.order(:category).pluck(:category).compact
    @difficulties    = [1, 2, 3]
    @only_unachieved = params[:only_unachieved] == "1"

    scope = scope.by_category(params[:category]).by_difficulty(params[:difficulty])
    scope = scope.unachieved_for(current_child) if user_signed_in? && current_child && @only_unachieved

    @milestones = scope.order(:difficulty, :id).page(params[:page]).per(20)

    if user_signed_in? && current_child
      achs = Achievement.where(child: current_child, milestone_id: @milestones.select(:id))
      @ach_by_ms = achs.index_by(&:milestone_id)
    end

    @parent_tip = safe_parent_tip(user_signed_in? ? current_child : nil)

  rescue => e
    # どこかで例外 → 500にせずデモで表示
    Rails.logger.error("[tasks#index] rescue #{e.class}: #{e.message}\n" + e.backtrace.take(12).join("\n"))
    @demo_mode = true
    render_demo_from_yaml
  end

  private

  # ==== 強耐性ユーティリティ ====
  def safe
    yield
  rescue => e
    Rails.logger.warn("[tasks#index] safe block skipped: #{e.class}: #{e.message}")
    nil
  end

  def data_source_exists_safely?(name)
    ActiveRecord::Base.connection_pool.with_connection { |c| c.data_source_exists?(name) }
  rescue => e
    Rails.logger.warn("[tasks#index] data_source_exists?(#{name}) failed: #{e.class}: #{e.message}")
    false
  end

  def safe_parent_tip(child)
    ParentTip.for(child: child, date: Date.current)
  rescue => e
    Rails.logger.warn("[tasks#index] ParentTip fallback: #{e.class}: #{e.message}")
    "あせらず、できることからやってみましょう。"
  end

  # ==== ヒントのバックフィル（DBが生きていて1件以上ある時だけ）====
  def try_backfill_hints_from_yaml!
    return unless Rails.env.production?

    need = safe { Milestone.unscoped.where(hint_text: [nil, ""]).limit(1).exists? }
    return unless need

    yaml_path = Rails.root.join("db", "seeds", "milestones.yml")
    return unless File.exist?(yaml_path)

    data  = YAML.safe_load(File.read(yaml_path), permitted_classes: [Date, Time, Symbol], aliases: true) || []
    index = data.index_by { |h| h["title"] }
    updated = 0
    Milestone.unscoped.where(hint_text: [nil, ""]).find_each do |m|
      src  = index[m.title] or next
      text = src["hint_text"].presence || src["hint"].presence or next
      m.update_columns(hint_text: text) # バリデーションを回避して静かに更新
      updated += 1
    end
    Rails.logger.warn("[tasks#index] backfilled hint_text for #{updated} milestones from YAML")
  rescue => e
    Rails.logger.warn("[tasks#index] backfill skipped: #{e.class}: #{e.message}")
  end

  # ==== デモ描画（DBに触らない）====
  def render_demo_from_yaml
    @demo_mode ||= true
    @age_band_label = "全年齢"

    yaml_path = Rails.root.join("db", "seeds", "milestones.yml")
    data =
      begin
        raw = File.exist?(yaml_path) ? File.read(yaml_path) : nil
        if raw.nil?
          Rails.logger.error("[tasks#index] YAML not found: #{yaml_path}")
          []
        else
          YAML.safe_load(raw, permitted_classes: [Date, Time, Symbol], aliases: true) || []
        end
      rescue => e
        Rails.logger.error("[tasks#index] YAML load error: #{e.class}: #{e.message}")
        []
      end

    rows = []
    Array(data).each_with_index do |h, idx|
      rows << DemoMilestone.new(
        idx + 1,
        h["title"], h["category"], h["difficulty"],
        h["min_months"], h["max_months"], h["description"],
        (h["hint_text"] || h["hint"] || "")
      )
    end

    if (band = params[:age_band].presence) && band != "all"
      i = band.to_i.clamp(0, 5)
      band_min = i * 12
      band_max = (i + 1) * 12
      rows.select! do |m|
        mn = (m.min_months || 0).to_i
        mx = (m.max_months || 10_000).to_i
        (mn < band_max) && (mx >= band_min)
      end
      @age_band_label = "#{i}–#{i + 1}歳"
    end
    rows.select! { |m| m.category == params[:category] }               if params[:category].present?
    rows.select! { |m| m.difficulty.to_i == params[:difficulty].to_i } if params[:difficulty].present?
    rows.sort_by! { |m| [m.difficulty.to_i, m.id] }

    if defined?(Kaminari)
      @milestones = Kaminari.paginate_array(rows).page(params[:page]).per(20)
    else
      @milestones = rows
    end

    @categories   = rows.map(&:category).compact.uniq.sort
    @difficulties = [1, 2, 3]
    @parent_tip   = safe_parent_tip(nil) # DBに触らない文言フォールバック

    render :index
  end

  def set_breadcrumbs
    return unless respond_to?(:add_crumb)
    add_crumb("ダッシュボード", dashboard_path) if user_signed_in?
    desired_band = params[:age_band].presence || "all"
    add_crumb("できるかな", tasks_path(age_band: desired_band))
  end
end