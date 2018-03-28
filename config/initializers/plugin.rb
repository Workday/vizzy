require 'find'

def all_plugins
  plugin_folder = Rails.root.join('app', 'plugins')
  Find.find(plugin_folder).select { |path| path =~ /.*\.rb/ }
end

def load_all_plugins
  all_plugins.each do |plugin|
    require plugin
  end
end

load_all_plugins