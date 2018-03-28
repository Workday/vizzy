module PluginBase
  module ClassMethods
    def repository
      @repository ||= []
    end

    def inherited(klass)
      repository << klass
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
  end

  # Retrieves plugin settings from postgres jsonb store
  # Params:
  # - project: project to fetch the setting from
  # - setting_symbol: setting to fetch passed in a symbol, ex :base_bamboo_build_url
  def get_plugin_setting_value(project, setting_symbol)
    plugin_settings = project.plugin_settings
    return '' if plugin_settings.blank? || plugin_settings[unique_id].blank?
    plugin_settings[unique_id][setting_symbol][:value]
  end

  # Adds project settings that will be shown in the new or edit Project form.
  # Params:
  # - project: project to add the settings to
  # - settings: hash of one or more settings that should follow the format of setting => value: '', display_name: '', and placeholder: '' so the project form can be populated correctly.
  # See /app/plugins/bamboo_plugin.rb for an example
  def add_plugin_settings_to_project(project, settings)
    return unless project.plugin_settings[unique_id].blank?
    settings = settings || {}
    settings[:enabled] = enabled?(project)
    project.plugin_settings[unique_id] = settings
  end

  # Determines whether or not a specific plugin is enabled
  # Params:
  # - project: project to fetch plugin settings from
  def enabled?(project)
    plugin_settings = project.plugin_settings
    setting_specific_hash = plugin_settings[unique_id]
    return false if plugin_settings.blank? || setting_specific_hash.blank?
    setting_specific_hash[:enabled]
  end
end