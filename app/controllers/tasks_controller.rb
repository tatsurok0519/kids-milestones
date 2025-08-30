class TasksController < ApplicationController
  before_action :set_breadcrumbs, only: :index

  def index
    Rails.logger.info("[tasks#index] params=#{params.to_unsafe_h.slice(:age_band, :category, :difficulty, :only_unachieved, :page)}")

    guest = !user_signed_in?

    # --- まずは「テーブルがあるか」チェック（DB未接続でも落ちない） ---
    has_ms_table =
      begin
        ActiveRecord::Base.connection.data_source_exists?("milestones")
      rescue => e
        Rails.logger.error("[tasks#index] data_source_exists? error: #{e.class}: #{e.message}")
        false
      end

    # --- ゲスト体験：テーブル無い/件数不明/0件 なら YAML に確実にフォールバック ---
    db_count = nil
    if has_ms_table
      begin
        db_count = Milestone.unscoped.count
      rescue => e
        Rails.logger.error("[tasks#index] Milestone.count failed: #{e.class}: #{e.message}")
        db_count = nil
      end
    end

    if guest && (!has_ms_table || db_count.nil? || db_count.zero?)
      Rails.logger.warn("[tasks#index] demo fallback: has_table=#{has_ms_table}, count=#{db_count.inspect}")
      return render_demo_from_yaml
    end

    # === ここから通常処理（DBあり・1件以上） ===
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

    @parent_tip = ParentTip.for(child: (user_signed_in? ? current_child : nil), date: Date.current)
  rescue => e
    Rails.logger.error("[tasks#index] #{e.class}: #{e.message}\n" + e.backtrace.take(12).join("\n"))
    raise
  end

  private

  # --- ゲスト用：YAMLから100件デモを描画（DBゼロ/未準備でも必ず動く） ---
  def render_demo_from_yaml
    @age_band_label = "全年齢"

    yaml_path = Rails.root.join("db", "seeds", "milestones.yml")
    unless File.exist?(yaml_path)
      Rails.logger.error("[tasks#index] YAML not found: #{yaml_path}")
      @milestones   = []
      @categories   = []
      @difficulties = [1, 2, 3]
      @parent_tip   = ParentTip.for(child: nil, date: Date.current)
      return render :index
    end

    data = YAML.safe_load_file(yaml_path) || []
    rows = Array(data).map do |h|
      Milestone.new(
        title:       h["title"],
        category:    h["category"],
        difficulty:  h["difficulty"],
        min_months:  h["min_months"],
        max_months:  h["max_months"],
        description: h["description"],
        hint_text:   (h["hint_text"] || h["hint"] || "")
      )
    end

    # 年齢帯フィルタ
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

    # カテゴリ／難易度フィルタ
    rows.select! { |m| m.category == params[:category] } if params[:category].present?
    rows.select! { |m| m.difficulty.to_i == params[:difficulty].to_i } if params[:difficulty].present?

    rows.sort_by! { |m| [m.difficulty.to_i, m.object_id] }

    if defined?(Kaminari)
      @milestones = Kaminari.paginate_array(rows).page(params[:page]).per(20)
    else
      @milestones = rows
    end

    @categories   = rows.map(&:category).compact.uniq.sort
    @difficulties = [1, 2, 3]
    @parent_tip   = ParentTip.for(child: nil, date: Date.current)

    render :index
  end

  def set_breadcrumbs
    add_crumb("ダッシュボード", dashboard_path) if user_signed_in?
    desired_band = params[:age_band].presence || "all"
    add_crumb("できるかな", tasks_path(age_band: desired_band))
  end
end