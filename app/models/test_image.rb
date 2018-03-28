require 'digest/md5'
class TestImage < ActiveRecord::Base

  PAPERCLIP_BASEDIR = Rails.root + 'public/'

  has_attached_file :image, path: ':rails_root/public/visual_images/:class/:attachment/:id_partition/:style/:filename', url: '/visual_images/:class/:attachment/:id_partition/:style/:filename', styles: {thumbnail: '125x', small: '300x'}
  validates_attachment :image, content_type: {content_type: ["application/octet-stream", "multipart/form-data", "image/jpg", "image/jpeg", "image/png", "image/gif"]}
  has_and_belongs_to_many :base_builds, class_name: 'Build', join_table: 'builds_base_images'
  has_and_belongs_to_many :successful_tests_builds, class_name: 'Build', join_table: 'builds_successful_tests'
  belongs_to :build
  belongs_to :test
  acts_as_commontable

  def validate_md5
    file_md5 = Digest::MD5.file(self.image.path).hexdigest
    provided_md5 = self.build.full_list_of_image_md5s[self.test_key]
    if file_md5.blank?
      :read_error
    elsif provided_md5.blank?
      :not_in_build
    elsif file_md5 != provided_md5
      :mismatched
    else
      self.md5 = provided_md5
      self.save
      :success
    end
  end

  def test=(test)
    super(test)
    self.test_key = self.test.ancestry_key
  end

  def remove_image_from_base_images
    self.approved = false
    self.clear_preapproval_information(false)
    self.save
  end

  # Preapproved status only depends on the image_pull_request_sha being present
  # We keep the pull request number around so we can view it later when it's a full approval
  def preapproved?
    self.image_pull_request_sha != nil
  end

  def preapprove(pr_num, sha)
    self.image_pull_request_sha = sha
    self.image_pull_request_number = pr_num
  end

  def clear_preapproval_information(keep_pr_number)
    self.image_pull_request_sha = nil
    unless keep_pr_number
      self.image_pull_request_number = nil
    end
  end
end
