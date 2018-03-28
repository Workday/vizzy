class Plugin
  include PluginBase
  attr_reader :unique_id

  # Plugins must call super with the unique id
  # Params:
  # - unique_id: unique id to pass to super
  def initialize(unique_id)
    @unique_id = unique_id.to_sym
  end

  # Default implementation for build_created_hook. To use this hook, define a build_created_hook(build) method in your plugin
  # Params:
  # - build: build that holds info that can be used for your plugins
  def build_created_hook(build)
    {not_implemented: 'Build Created Hook'}
  end

  # Default implementation for build_committed_hook. To use this hook, define a build_committed_hook(build) method in your plugin
  # Params:
  # - build: build that holds info that can be used for your plugins
  def build_committed_hook(build)
    {not_implemented: 'Build Committed Hook'}
  end

  # Default implementation for build_failed_hook. To use this hook, define a build_failed_hook(build) method in your plugin
  # Params:
  # - build: build that holds info that can be used for your plugins
  def build_failed_hook(build)
    {not_implemented: 'Build Failed Hook'}
  end
end