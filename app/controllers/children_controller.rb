class ChildrenController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child, only: [:edit, :update, :destroy]
  before_action -> { add_crumb("子ども", children_path) }

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
      session[:current_child_id] = @child.id
      redirect_to dashboard_path, notice: "登録しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @child
  end

  def update
    authorize @child
    if @child.update(child_params)
      redirect_to children_path, notice: "更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @child = current_user.children.find(params[:id])
    @child.destroy!

    # 削除した子が選択中だったらセッションを必ず空にする
    session.delete(:current_child_id) if session[:current_child_id].to_i == @child.id

    redirect_to children_path, notice: "子どもを削除しました。"
  end

  private

  def set_child
    @child = policy_scope(Child).find(params[:id])
  end

  def child_params
    params.require(:child).permit(:name, :birthday, :photo)
  end
end