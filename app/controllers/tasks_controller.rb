class TasksController < ApplicationController
  before_action :set_breadcrumbs, only: :index

  def index
    Rails.logger.info("[tasks#index] params=#{params.to_unsafe_h.slice(:age_band, :category, :difficulty, :only_unachieved, :page)}")

    guest = !user_signed_in?

    # milestones テーブルがあるか
    has_ms_table =
      begin
        ActiveRecord::Base.connection.data_source_exists?("milestones")
      rescue => e
        Rails.logger.error("[tasks#index] data_source_exists? error: #{e.class}: #{e.message}")
        false
      end

    # ★ ゲスト体験：テーブルが無い「または0件」なら YAML フォールバック
    if guest && (!has_ms_table || (has_ms_table && Milestone.unscoped.count.zero?))
      Rails.logger.warn("[tasks#index] demo fallback: has_table=#{has_ms_table}, count=#{has_ms_table ? Milestone.unscoped.count : 'n/a'}")
      return render_demo_from_yaml
    end

    # === ここから通常処理（DBあり・件数あり） ===
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
    Rails.logger.error("[tasks#index] #{e.class}: #{e.message}\n" + e.backtrace.take(10).join("\n"))
    raise
  end

  private

  # ★ YAML デモ描画（ゲスト・DB未準備/空のときに使用）
  def render_demo_from_yaml
    @age_band_label = "全年齢"

    yaml_path = Rails.root.join("db", "seeds", "milestones.yml")
    data = File.exist?(yaml_path) ? YAML.safe_load_file(yaml_path) : []
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

    # --- フィルタ（年齢帯 / カテゴリ / 難易度）を Ruby で適用 ---
    if (band = params[:age_band].presence) && band != "all"
      i = band.to_i.clamp(0, 5)
      band_min = i * 12
      band_max = (i + 1) * 12
      rows.select! do |m|
        mn = (m.min_months || 0).to_i
        mx = (m.max_months || 10_000).to_i
        # 月齢レンジが年齢帯と重なっていれば採用
        (mn < band_max) && (mx >= band_min)
      end
      @age_band_label = "#{i}–#{i + 1}歳"
    end

    if (cat = params[:category].presence)
      rows.select! { |m| m.category == cat }
    end

    if (dif = params[:difficulty].presence)
      d = dif.to_i
      rows.select! { |m| m.difficulty.to_i == d }
    end

    # 表示並び＝難易度→擬似ID
    rows.sort_by! { |m| [m.difficulty.to_i, m.object_id] }

    # --- ページング（Kaminari 有無で分岐） ---
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