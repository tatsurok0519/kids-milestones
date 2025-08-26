class TasksController < ApplicationController
  # 認証なしで見せたいので authenticate_user! は書かない
  def index
    @milestones = Milestone.order(:difficulty, :id)
  end
end