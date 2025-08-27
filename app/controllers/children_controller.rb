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

  def destroy
    name = @child.name
    # Child は has_one_attached :photo なので、destroy で添付も自動的に purge_later されます
    # Achievements は dependent: :destroy のため、関連の達成履歴も一緒に削除されます
    if @child.destroy
      redirect_to children_path, notice: "#{name} のカードを削除しました（写真・達成履歴も削除されました）。"
    else
      redirect_to children_path, alert: "削除に失敗しました。もう一度お試しください。"
    end
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