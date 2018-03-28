# Helper class for accessing vizzy.yaml config values preventing crashes if values don't exist
class VizzyConfig
  include Singleton

  def initialize
    @config = Rails.configuration.vizzy
  end

  # Get config value or nil if it doesn't exist
  # params:
  # - Array of config values in order of lookup
  def get_config_value(array)
    value = @config
    array.each do |key|
      begin
        value = value.fetch(key)
      rescue
        return nil
      end
    end
    value
  end

  # Convenience function to know if the server is configured to use ldap authentication
  def is_ldap_auth
    get_config_value(['devise', 'auth_strategy']) == 'LDAP'
  end
end