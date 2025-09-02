Rails.application.config.filter_parameters += %i[
  password password_confirmation current_password
  email
  token api_key secret key base64
  authenticity_token
  credit_card number cvv cvc
]