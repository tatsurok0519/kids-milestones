class TasksController < ApplicationController
  before_action :set_breadcrumbs, only: :index

  DemoMilestone = Struct.new(:id, :title, :category, :difficulty, :min_months, :max_months, :description, :hint_text) do
    def difficulty_stars
      d = difficulty.to_i.clamp(0, 3)
      "★" * d + "☆" * (3 - d)
    end
    def age_band_labels
      mn = (min_months || 0).to_i
      mx = (max_months || 71).to_i
      s  = (mn / 12).clamp(0, 5)
      e  = (([mx - 1, mn].max) / 12).clamp(0, 5)
      (s..e).map { |i| "#{i}–#{i + 1}歳" }.uniq.join(" ")
    end
  end
  private_constant :DemoMilestone

  def index
    Rails.logger.info("[tasks#index] params=#{params.to_unsafe_h.slice(:age_band, :category, :difficulty, :only_unachieved, :page)}")

    # 1) テーブル生存確認
    has_ms_table = data_source_exists_safely?("milestones")
    db_count     = has_ms_table ? safe { Milestone.unscoped.count } : nil

    # 2) DB未準備 or 0件 → デモ表示（YAML）
    if !has_ms_table || db_count.nil? || db_count.zero?
      Rails.logger.warn("[tasks#index] DEMO FALLBACK: has_table=#{has_ms_table}, count=#{db_count.inspect}")
      @demo_mode = true
      return render_demo_from_yaml
    end

    # 3) 通常表示（必要なら hint_text の穴埋め）
    try_backfill_hints_from_yaml! # 本番のみ・必要時だけ

    # === 年齢帯 ===
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

      if Milestone.respond_to?(:for_age_band) || Milestone.singleton_class.method_defined?(:for_age_band)
        scope = Milestone.for_age_band(@age_band_index)
      else
        if column?(:min_months) && column?(:max_months)
          band_min = @age_band_index * 12
          band_max = (@age_band_index + 1) * 12
          scope = Milestone.where("(COALESCE(min_months,0) < ?) AND (COALESCE(max_months,100000) >= ?)", band_max, band_min)
        elsif column?(:age_band_index)
          scope = Milestone.where(age_band_index: @age_band_index)
        else
          scope = Milestone.all
        end
      end
    end

    # === フィルタUI選択肢（N+1関係なし、小さめクエリ） ===
    @categories   = safe { Milestone.distinct.order(:category).pluck(:category).compact } || []
    @difficulties = [1, 2, 3]
    @only_unachieved = params[:only_unachieved] == "1"

    # === カテゴリ・難易度 ===
    if params[:category].present?
      scope =
        if scope.respond_to?(:by_category)
          scope.by_category(params[:category])
        else
          scope.where(category: params[:category])
        end
    end
    if params[:difficulty].present?
      scope =
        if scope.respond_to?(:by_difficulty)
          scope.by_difficulty(params[:difficulty])
        else
          scope.where(difficulty: params[:difficulty])
        end
    end

    # === 未達成のみ（ログイン & 子ども選択時）===
    if user_signed_in? && current_child && @only_unachieved
      if scope.respond_to?(:unachieved_for)
        scope = scope.unachieved_for(current_child)
      else
        # サブクエリで達成済み milestone を除外（N+1回避）
        done_ids = Achievement.where(child: current_child, achieved: true).select(:milestone_id)
        scope = scope.where.not(id: done_ids)
      end
    end

    # === 取得・ページング ===
    # ※ ここでは includes は付けない（後段で “表示中IDだけ” achievements を一括取得するため）
    @milestones =
      if scope.respond_to?(:page)
        scope.order(:difficulty, :id).page(params[:page]).per(20)
      else
        scope.order(:difficulty, :id)
      end

    # === N+1対策の肝：表示中マイルストーンに対する達成レコードを 1 クエリで回収 ===
    if user_signed_in? && current_child && @milestones.present?
      achs = Achievement
               .where(child_id: current_child.id, milestone_id: @milestones.select(:id))
               .to_a
      @ach_by_ms = achs.index_by(&:milestone_id)
    else
      @ach_by_ms = {}
    end

    # === 今日の子育てメッセージ ===
    @parent_tip = safe_parent_tip(user_signed_in? ? current_child : nil)

  rescue => e
    # 例外はログだけ吐いてデモにフォールバック
    Rails.logger.error("[tasks#index] rescue #{e.class}: #{e.message}\n" + e.backtrace.take(12).join("\n"))
    @demo_mode = true
    render_demo_from_yaml
  end

  private

  def safe
    yield
  rescue => e
    Rails.logger.warn("[tasks#index] safe skipped: #{e.class}: #{e.message}")
    nil
  end

  def column?(name)
    Milestone.column_names.include?(name.to_s)
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
      m.update_columns(hint_text: text)
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
        raw ? (YAML.safe_load(raw, permitted_classes: [Date, Time, Symbol], aliases: true) || []) : []
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
      i        = band.to_i.clamp(0, 5)
      band_min = i * 12
      band_max = (i + 1) * 12
      rows.select! do |m|
        mn = (m.min_months || 0).to_i
        mx = (m.max_months || 10_000).to_i
        (mn < band_max) && (mx >= band_min)
      end
      @age_band_label = "#{i}–#{i + 1}歳"
    end
    rows.select! { |m| m.category.to_s == params[:category].to_s }     if params[:category].present?
    rows.select! { |m| m.difficulty.to_i == params[:difficulty].to_i } if params[:difficulty].present?
    rows.sort_by! { |m| [m.difficulty.to_i, m.id] }

    @milestones =
      if defined?(Kaminari)
        Kaminari.paginate_array(rows).page(params[:page]).per(20)
      else
        rows
      end

    @categories   = rows.map(&:category).compact.uniq.sort
    @difficulties = [1, 2, 3]
    @parent_tip   = safe_parent_tip(nil)

    render :index
  end

  def set_breadcrumbs
    return unless respond_to?(:add_crumb)
    add_crumb("メイン", dashboard_path) if user_signed_in?
    desired_band = params[:age_band].presence || "all"
    add_crumb("できるかな", tasks_path(age_band: desired_band))
  end
end