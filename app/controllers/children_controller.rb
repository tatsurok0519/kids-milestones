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

  def show
    # 迷い込んだURLは一覧へ返す
    redirect_to children_path
  end

  def create
    @child = current_user.children.new(child_params)

    if @child.save
      redirect_to children_path, notice: "子どもを登録しました。", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # フォームのチェックボックス値を安全に取り出し、child_params からは必ず除外する
    raw_remove  = params.dig(:child, :remove_photo)
    remove_flag = ActiveModel::Type::Boolean.new.cast(raw_remove)
    params[:child]&.delete(:remove_photo)

    if @child.update(child_params)
      @child.photo.purge_later if remove_flag && @child.photo.attached?

      flash[:notice] = "お子さまの情報を更新しました。"
      location = children_path

      if turbo_frame_request?
        # ★ ここが重要：303 + Turbo-Location + Location を明示
        response.set_header("Turbo-Location", location)
        response.set_header("Location",       location)
        head :see_other
      else
        redirect_to location, status: :see_other
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @child.destroy!
    redirect_to children_path, notice: "削除しました。", status: :see_other
  end

  private

  def set_child
    @child = policy_scope(Child).find(params[:id])
    authorize @child
  end

  # ← ここで :birthday を必ず許可
  def child_params
    params.require(:child).permit(:name, :birthday, :photo)
  end
end