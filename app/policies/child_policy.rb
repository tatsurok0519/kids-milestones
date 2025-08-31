class ChildPolicy < ApplicationPolicy
  def index?   = user.present?
  def new?     = create?
  def create?  = user.present?
  def show?    = record.user_id == user.id
  def update?  = show?
  def destroy? = show?
  def use?     = show?   # 既存用途互換

  class Scope < Scope
    def resolve
      user ? scope.where(user_id: user.id) : scope.none
    end
  end
end