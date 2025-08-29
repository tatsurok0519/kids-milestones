class ChildPolicy < ApplicationPolicy
  def show?    = owner?
  def update?  = owner?
  def destroy? = owner?
  def select?  = owner?   # ダッシュボードでの選択など
  def use?     = owner?   # 子に紐づく操作全般のガードに使う

  class Scope < Scope
    def resolve
      scope.where(user_id: user.id)
    end
  end

  private

  def owner?
    record.user_id == user.id
  end
end