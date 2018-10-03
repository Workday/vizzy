require 'net/ldap'
require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class LdapAuthenticatable < Authenticatable
      def authenticate!
        if params[:user]
          user = nil
          auth_config = VizzyConfig.instance.get_config_value(['devise'])
          if Rails.env.development? || Rails.env.test? || Rails.env.ci_test?
            # No need to connect to ldap for development environment, just let them sign in
            user = User.find_or_create_by(email: email)
          elsif !password.blank?
            # Use LDAP for production environment
            ldap = Net::LDAP.new
            ldap.host = auth_config['ldap_host']
            ldap.port = auth_config['ldap_port']
            ldap.base = auth_config['ldap_base']
            internal_domain = auth_config['ldap_email_internal_domain']
            ldap.auth username_from_email + internal_domain, password

            ldap_email_domain = auth_config['ldap_email_domain']

            if ldap.host.blank? || ldap.port.blank? || ldap.base.blank? || internal_domain.blank? || ldap_email_domain.blank?
              raise "ldap auth configuration missing -- host: #{ldap.host}, port: #{ldap.port}, base: #{ldap.base}, internal_domain: #{internal_domain}, ldap_email_domain: #{ldap_email_domain}"
            end

            if email.downcase.include?(ldap_email_domain) && ldap.bind
              user = User.find_or_create_by(email: email)
            else
              fail(:invalid_login)
              return
            end
          end
          if user.nil?
            fail(:invalid_login)
          else
            if user.new_record?
              user.save!
            end
            success!(user)
          end
        end
      end

      def username_from_email
        email.split('@').first
      end

      def email
        params[:user][:email]
      end

      def password
        params[:user][:password]
      end
    end
  end
end

Warden::Strategies.add(:ldap_authenticatable, Devise::Strategies::LdapAuthenticatable)