class ChildrenController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child, only: [:edit, :update, :destroy]

  def index
    @children = current_user.children.with_attached_photo.order(created_at: :asc)
  end

  def new
    @child = current_user.children.new
  end

  def create
    @child = current_user.children.new(child_params)
    if @child.save
      redirect_to children_path, notice: "#{@child.name} を登録しました。"
    else
      flash.now[:alert] = "入力内容を確認してください。"
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @child.update(child_params)
      redirect_to children_path, notice: "#{@child.name} のプロフィールを更新しました。"
    else
      flash.now[:alert] = "更新に失敗しました。入力内容を確認してください。"
      render :edit, status: :unprocessable_entity
    end
  end

  def select
    child = current_user.children.find(params[:id])  # 自分の子か確認
    session[:current_child_id] = child.id
    redirect_back fallback_location: dashboard_path,
                  notice: "#{child.name}を選択しました。",
                  status: :see_other
  end
  
  def destroy
    @child = current_user.children.find(params[:id])
    name = @child.name
    @child.destroy
    redirect_to children_path, notice: "#{name}を削除しました。", status: :see_other
  end

  private

  def set_child
    # 所有者チェック：他ユーザーの子どもは取れない
    @child = current_user.children.find(params[:id])
  end

  def child_params
    params.require(:child).permit(:name, :birthday, :photo)
  end
end