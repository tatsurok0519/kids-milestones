class AchievementPolicy < ApplicationPolicy
  # AchievementsController#upsert 専用
  def upsert?
    user.present? && record.child && record.child.user_id == user.id
    # もし admin を許可したいなら:
    # (user.present? && record.child && record.child.user_id == user.id) || user.admin?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user
      scope.joins(:child).where(children: { user_id: user.id })
    end
  end
end