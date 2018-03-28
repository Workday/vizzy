require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module VisualAutomation
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.time_zone = 'Pacific Time (US & Canada)'

    # load vizzy server config
    vizzy_config_path = Rails.root.join('config', 'vizzy.yaml')
    unless File.exist?(vizzy_config_path)
      raise "Missing vizzy.yaml configuration file"
    end
    config.vizzy = config_for(vizzy_config_path)
  end
end
