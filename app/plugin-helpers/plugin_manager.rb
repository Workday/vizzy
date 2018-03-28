require 'singleton'

class PluginManager
  include Singleton

  # Loads plugins and adds them to the class variable @@plugin_hash
  # Params:
  # - project: project to load the plugins for
  def for_project(project)
    @@plugins_hash = {}
    load_plugins(project)
    yield self if block_given?
    self
  end

  # Runs the build created hook for all enabled plugins
  # Params:
  # - build: build to run the build created hook for
  def run_build_created_hook(build)
    run_hook(build.project) do |plugin|
      plugin.build_created_hook(build)
    end
  end

  # Runs the build commited hook for all enabled plugins
  # Params:
  # - build: build to run the build commited hook for
  def run_build_commited_hook(build)
    run_hook(build.project) do |plugin|
      plugin.build_committed_hook(build)
    end
  end

  # Runs the build failed hook for all enabled plugins
  # Params:
  # - build: build to run the build failed hook for
  def run_build_failed_hook(build)
    run_hook(build.project) do |plugin|
      plugin.build_failed_hook(build)
    end
  end

  # Returns an array of all plugin classes
  def plugins
    plugins_hash.map {|plugin_hash| plugin_hash.last}
  end

  # Returns an array of plugin classes that are enabled
  def enabled_plugins(project)
    plugins.select {|plugin| plugin.enabled?(project)}
  end

  # Returns a hash of plugin unique_id to plugin class
  def plugins_hash
    @@plugins_hash
  end

  # Retrieves the plugin class name
  # Params:
  # - unique_id: unique id of plugin to get the class name
  def get_plugin_name_from_unique_id(unique_id)
    @@plugins_hash[unique_id].class.name
  end

  # Checks if a plugin is enabled on a project
  # Params:
  # - project: project to look up plugin settings
  # - name: name of plugin to check -- called via PluginClass.name
  def is_plugin_enabled(project, name)
    for_project(project)
    project.plugin_settings.each do |plugin_setting|
      plugin_key = plugin_setting.first
      plugin_hash = plugin_setting.second
      plugin_name = get_plugin_name_from_unique_id(plugin_key)
      if plugin_name == name && plugin_hash[:enabled]
        return plugin_hash
      end
    end
    nil
  end

  private

  # Creates all plugins and loads them into the plugin hash. Also adds plugin settings to the projects database table
  # Params:
  # - project: project to add plugin settings to
  def load_plugins(project)
    Plugin.repository.each do |build_plugin|
      id, _ = build_plugin.instance_method(:initialize).source_location
      unless @@plugins_hash[id.to_sym]
        plugin = build_plugin.new(id)
        @@plugins_hash[id.to_sym] = plugin
        plugin.add_plugin_settings_to_project(project)
      end
    end
  end

  # Runs plugin hook for all enabled plugins
  # Yield:
  # - plugin: yields plugin so a specific hook can be run
  def run_hook(project)
    errors = []
    enabled_plugins(project).each do |plugin|
      hook_result = yield(plugin)
      add_to_errors_if_error(hook_result, errors)
    end
    {errors: errors}
  end

  # Filters the hook result for not implemented and adds errors if present
  # Params:
  # - hook_result: the result to inspect for errors
  # - errors: array containing all errors to be returned to the caller
  def add_to_errors_if_error(hook_result, errors)
    if hook_result.key?(:not_implemented)
      # Do nothing, method not implemented for this plugin
    elsif hook_result.key?(:error)
      errors.push(hook_result)
    end
    errors
  end
end