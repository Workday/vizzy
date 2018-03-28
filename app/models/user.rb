class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  if VizzyConfig.instance.is_ldap_auth
    devise :database_authenticatable, :rememberable, :trackable, :validatable
  else
    devise :database_authenticatable, :registerable,
           :rememberable, :trackable, :validatable
  end

  acts_as_token_authenticatable
  acts_as_commontator
  belongs_to :diff
  after_initialize :update_user_fields

  def update_user_fields
    self.username = self.email.split('@').first if self.username.blank?
    self.admin = true if self.owner?
  end

  def owner?
    admins = Rails.application.secrets.ADMIN_EMAILS.split(',').map(&:strip)
    admins.include?(email)
  end

  def role
    if owner?
      :Owner
    elsif admin?
      :Admin
    else
      :Member
    end
  end

  def password_required?
    false
  end

  def display_name
    self.username.blank? ? self.email : self.username
  end
end

