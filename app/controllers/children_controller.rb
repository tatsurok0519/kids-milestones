class ChildrenController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child, only: [:show, :edit, :update, :destroy]

  def show
    # @child は set_child 済み
  end
  
  def index
    @children = current_user.children.with_attached_photo.order(created_at: :asc)
  end

  def new
    @child = current_user.children.new
  end

  def create
    @child = current_user.children.new(child_params)
    if @child.save
      redirect_to @child, notice: "子どもを登録しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    # @child は set_child 済み
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

  def select
    child = current_user.children.find(params[:id])  # 自分の子か確認
    session[:current_child_id] = child.id
    redirect_back fallback_location: dashboard_path,
                  notice: "#{child.name}を選択しました。",
                  status: :see_other
  end

  def destroy
    name = @child.name
    @child.destroy
    redirect_to children_path, notice: "#{name}を削除しました。", status: :see_other
  end

  private
  def set_child
    @child = current_user.children.find(params[:id])
  end

  def child_params
    params.require(:child).permit(:name, :birthday, :photo) # ← :remove_photo を削除
  end
end