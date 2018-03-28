Bugsnag.configure do |config|
  config.api_key = Rails.application.secrets.BUGSNAG_API_KEY
  config.notify_release_stages = ['production']
end
