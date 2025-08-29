# app/controllers/children_controller.rb
class ChildrenController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child, only: [:show, :edit, :update, :destroy]

  # 一覧：自分の子だけ
  def index
    @children = policy_scope(Child).with_attached_photo.order(created_at: :asc)
  end

  # 詳細
  def show
    # @child は set_child 済み（authorize 済み）
  end

  # 新規
  def new
    @child = current_user.children.new
  end

  # 作成
  def create
    @child = current_user.children.new(child_params)
    if @child.save
      # 作成直後に選択しておくとUXが良い（任意）
      session[:current_child_id] = @child.id
      redirect_to @child, notice: "子どもを登録しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # 編集
  def edit
    # @child は set_child 済み（authorize 済み）
  end

  # 更新
  def update
    # @child は set_child 済み（authorize 済み）
    remove_flag = ActiveModel::Type::Boolean.new.cast(params.dig(:child, :remove_photo))
    new_upload  = params.dig(:child, :photo).present?

    if @child.update(child_params)
      if remove_flag && !new_upload && @child.photo.attached?
        @child.photo.purge_later
      end
      redirect_to @child, notice: "子ども情報を更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 選択（ダッシュボード等からの切替）
  def select
    child = policy_scope(Child).find(params[:id])   # 自分の子だけから検索
    authorize child, :select?                       # ChildPolicy#select?
    session[:current_child_id] = child.id
    redirect_back fallback_location: dashboard_path,
                  notice: "#{child.name}を選択しました。",
                  status: :see_other
  end

  # 削除
  def destroy
    name = @child.name
    @child.destroy
    redirect_to children_path, notice: "#{name}を削除しました。", status: :see_other
  end

  private

  # 自分の子だけから取得し、各アクションに応じて自動で権限判定
  # （show? / edit?→update? / destroy?）
  def set_child
    @child = policy_scope(Child).find(params[:id])
    authorize @child
  end

  def child_params
    # remove_photo は別途フラグ処理するので permit しない
    params.require(:child).permit(:name, :birthday, :photo)
  end
end