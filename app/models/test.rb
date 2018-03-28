class Test < ActiveRecord::Base
  has_many :test_images
  has_ancestry

  def current_base_image
    self.test_images.where(approved: true).last
  end

  def self.create_or_find(project_id, ancestry_key)
    return nil if ancestry_key.blank?
    test = Test.where(project_id: project_id, ancestry_key: ancestry_key).first
    return test unless test.nil?
    create_test_tree(project_id, get_ancestry_key_array(ancestry_key))
  end

  def self.create_test_tree(project_id, ancestry_key_array, parent = nil)
    return parent if ancestry_key_array.empty?
    ancestry_key = ancestry_key_array.shift
    test_name = ancestry_key.split('/').last
    test = Test.where(project_id: project_id, ancestry_key: ancestry_key).first
    if test.nil?
      test = Test.create(project_id: project_id, name: test_name, ancestry_key: ancestry_key, parent: parent)
    end
    create_test_tree(project_id, ancestry_key_array, test)
  end

  def self.get_ancestry_key_array(ancestry_key)
    test_node_data = []
    ancestry_key.split('/').each do |word|
      if test_node_data.empty?
        test_node_data.push(word)
      else
        test_string = test_node_data.last
        test_node_data.push("#{test_string}/#{word}")
      end
    end
    test_node_data
  end

  def test_image_history
    self.test_images.where(approved: true).sort_by {|test_img| test_img.image_updated_at}.reverse
  end
end
