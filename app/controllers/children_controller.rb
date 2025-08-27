class ChildrenController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child,   only: [:edit, :update, :destroy]

  def index
    @children = current_user.children.with_attached_photo.order(created_at: :asc)
  end

  def new
    @child = current_user.children.new
  end

  def create
    @child = current_user.children.new(child_params)
    if @child.save
      redirect_to children_path, notice: "お子さまカードを登録しました。"
    else
      flash.now[:alert] = "登録に失敗しました。入力内容をご確認ください。"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # 写真を削除チェックが付いている場合
    if params[:child].delete(:remove_photo) == "1"
      @child.photo.purge_later if @child.photo.attached?
    end

    if @child.update(child_params)
      redirect_to children_path, notice: "お子さまプロフィールを更新しました。"
    else
      flash.now[:alert] = "更新に失敗しました。入力内容をご確認ください。"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @child.destroy
    redirect_to children_path, notice: "お子さまカードを削除しました。"
  end

  private

  def set_child
    # 自分の子どもだけ編集できる（他人のIDは404）
    @child = current_user.children.find(params[:id])
  end

  def child_params
    params.require(:child).permit(:name, :birthday, :photo)
  end
end