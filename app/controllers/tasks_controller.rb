class TasksController < ApplicationController
  # パンくず：常に「できるかな」に統一（ダッシュボード → できるかな）
  before_action :set_breadcrumbs, only: :index

  def index
    # おためし判定
    guest = !user_signed_in?

    # 年齢帯: "0".."5" or "all" or nil
    # おためし時は常に "all"（0件を避け、必ず全件表示）
    band_param = params[:age_band].presence || (guest ? "all" : nil)

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

    # フィルタ選択肢
    @categories      = Milestone.distinct.order(:category).pluck(:category).compact
    @difficulties    = [1, 2, 3]
    @only_unachieved = params[:only_unachieved] == "1"

    # フィルタ適用
    scope = scope.by_category(params[:category]) if params[:category].present?
    scope = scope.by_difficulty(params[:difficulty].to_i) if params[:difficulty].present?

    # 未達のみ（ログイン & 子選択時）
    if user_signed_in? && current_child && @only_unachieved
      scope = scope.unachieved_for(current_child)
    end

    # ページング（並びは難易度→ID）
    per_page = 20
    @milestones = scope.order(:difficulty, :id).page(params[:page]).per(per_page)

    # フェイルセーフ：DBが空でも、おためし時は seeds/milestones.yml から表示
    if guest && @milestones.total_count.zero?
      yaml_path = Rails.root.join("db", "seeds", "milestones.yml")
      if File.exist?(yaml_path)
        data = YAML.safe_load_file(yaml_path) || []
        rows = data.map do |h|
          Milestone.new(
            title:       h["title"],
            category:    h["category"],
            difficulty:  h["difficulty"],
            min_months:  h["min_months"],
            max_months:  h["max_months"],
            description: h["description"],
            hint_text:   h["hint_text"] || h["hint"] || ""   # ★ ここを追加
          )
        end
        # 画面フィルタが指定されていればYAMLにも適用（age_band=all 前提）
        rows.select! { |m| m.category.to_s == params[:category].to_s } if params[:category].present?
        rows.select! { |m| m.difficulty.to_i == params[:difficulty].to_i } if params[:difficulty].present?

        sorted = rows.sort_by { |m| [m.difficulty.to_i, m.title.to_s] }
        @milestones = Kaminari.paginate_array(sorted).page(params[:page]).per(per_page)
        flash.now[:notice] = "おためし表示：DB未登録のためシードの100件を表示中"
      end
    end

    # ログイン時のみ：表示中タスクの達成状況を一括取得（ゲストはJSで扱わない＝非表示）
    if user_signed_in? && current_child
      achs = Achievement.where(child: current_child, milestone_id: @milestones.select(:id))
      @ach_by_ms = achs.index_by(&:milestone_id)
    else
      @ach_by_ms = {}
    end

    # 今日の子育てメッセージ
    @parent_tip = ParentTip.for(child: (user_signed_in? ? current_child : nil), date: Date.current)
  end

  private

  def set_breadcrumbs
    add_crumb("ダッシュボード", dashboard_path) if user_signed_in?
    desired_band = params[:age_band].presence || "all"
    add_crumb("できるかな", tasks_path(age_band: desired_band))
  end
end