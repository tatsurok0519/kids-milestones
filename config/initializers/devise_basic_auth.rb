Rails.application.config.to_prepare do
  DeviseController.include BasicAuthProtection
end