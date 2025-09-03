module Breadcrumbs
  extend ActiveSupport::Concern
  included do
    helper_method :breadcrumb_trail
  end

  def breadcrumb_trail
    @breadcrumb_trail ||= []
  end

  # 例: add_crumb "メイン", dashboard_path
  def add_crumb(label, path = nil)
    breadcrumb_trail << [label, path]
  end
end