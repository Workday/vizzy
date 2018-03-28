class Diff < ActiveRecord::Base
  belongs_to :old_image, :class_name => 'TestImage'
  belongs_to :new_image, :class_name => 'TestImage'
  belongs_to :build, :class_name => 'Build'
  belongs_to :approved_by, :class_name => 'User'
  has_many :jiras, dependent: :destroy
  has_attached_file :differences, path: ':rails_root/public/visual_images/:class/:attachment/:id_partition/:style/:filename', url: '/visual_images/:class/:attachment/:id_partition/:style/:filename', styles: {thumbnail: '125x', small: '300x'}
  validates_attachment :differences, content_type: {content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"]}

  def approve(current_user)
    if self.build.pull_request_number != '-1'
      # This is the preapproved pull request case, don't approve the image, just store the commit_sha with the
      # associated new image
      # Add sha and pull request number to the image
      self.new_image.preapprove(self.build.pull_request_number, self.build.commit_sha)
    else
      # This should rarely happen, but in the case of a diff in the branch build plan, allow a user to approve the
      # image immediately
      self.new_image.approved = true
      cleanup_related_diffs current_user, true
    end

    # Mark diff that an action has been taken, so it is listed in the "Images approved with this build" section
    self.new_image.user_approved_this_build = true
    self.new_image.save
    self.approved_by = current_user
    self.approved = true
    self.save
  end

  # Unapprove a given diff, used for if a mistake was made. Only available if the image had previously been approved
  def unapprove
    if self.build.pull_request_number != '-1'
      # Clear sha and pull request number
      self.new_image.clear_preapproval_information(false)
    else
      self.new_image.approved = false
    end

    # Clear fields that mark diff that an action has been taken, so it is listed in the "Diffs waiting for approval" section
    self.new_image.user_approved_this_build = false
    self.new_image.save
    self.approved_by = nil
    self.approved = false
    self.save
  end

  # After `diff` has been approved, make changes to all the other diffs with the same test. This is for the
  # multiple preapproval case
  def cleanup_related_diffs(current_user, include_current)
    self.build.diffs.each do |other_diff|
      if (other_diff != self || include_current) && other_diff.old_image.test_key == self.old_image.test_key
        # Remove preapproval metadata
        other_diff.old_image.clear_preapproval_information(false)
        other_diff.old_image.save

        # Mark diff approved, so it is listed in the "Images approved with this build" section with the related diff that had its image was approved
        other_diff.approved = true
        other_diff.approved_by = current_user
        other_diff.save
      end
    end
  end

  # Branch Build Only - Special case method for when multiple developers make changes on the same image, view with multiple diffs shows and they are allowed to
  # approve either one of the old images
  def approve_old_image(current_user)
    logger.info "Clicked approve old image on diff: #{diff.id}"

    # Approved image should be marked back to 1 associated image because the user just took action and ruled the other images out
    self.old_image.approved = true
    self.old_image.save

    self.approved = true
    self.approved_by = current_user
    self.save

    cleanup_related_diffs current_user, false
  end

  def approved_by_username
    self.approved_by.nil? ? 'Unknown' : self.approved_by.display_name
  end
end
