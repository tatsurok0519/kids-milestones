class ChildrenController < ApplicationController
  before_action :set_child, only: [:show, :edit, :update, :destroy]

  def index
    @children = current_user.children.with_attached_photo.order(:created_at)
  end

  def show
  end

  def new
    @child = current_user.children.new
  end

  def create
    @child = current_user.children.new(child_params)
    if @child.save
      redirect_to children_path, notice: "子どもプロフィールを登録しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @child.update(child_params)
      redirect_to children_path, notice: "子どもプロフィールを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @child.destroy
    redirect_to children_path, notice: "子どもプロフィールを削除しました。"
  end

  private

  def set_child
    @child = current_user.children.find(params[:id])
  end

  def child_params
    params.require(:child).permit(:name, :birthday, :photo)
  end
end