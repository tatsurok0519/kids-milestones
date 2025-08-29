class AchievementPolicy < ApplicationPolicy
  # AchievementsController#upsert 専用の権限
  def upsert?
    record.child.user_id == user.id
  end

  class Scope < Scope
    def resolve
      scope.joins(:child).where(children: { user_id: user.id })
    end
  end
end