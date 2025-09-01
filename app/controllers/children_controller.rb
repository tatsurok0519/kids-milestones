class ChildrenController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child, only: [:edit, :update, :destroy]

  def index
    @children = policy_scope(Child).with_attached_photo.order(:created_at)
  end

  def new
    @child = current_user.children.build
    authorize @child
  end

  def create
    @child = current_user.children.build(child_params)
    authorize @child

    if @child.save
      # 追加した子を選択状態に
      select_current_child(@child)
      redirect_to children_path, notice: "子どもを登録しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # 画像の削除フラグを先に見る
    remove_flag = ActiveModel::Type::Boolean.new.cast(params.dig(:child, :remove_photo))

    if @child.update(child_params)
      @child.photo.purge_later if remove_flag && @child.photo.attached?
      redirect_to children_path, notice: "更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    was_current = (current_child&.id == @child.id)
    @child.destroy
    select_current_child(nil) if was_current
    redirect_to children_path, notice: "削除しました。"
  end

  private

  def set_child
    @child = policy_scope(Child).find(params[:id])
    authorize @child
  end

  # ← ここで :birthday を必ず許可
  def child_params
    params.require(:child).permit(:name, :birthday, :photo, :remove_photo)
  end
end