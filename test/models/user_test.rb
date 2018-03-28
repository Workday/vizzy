require 'test_helper'

class UserTest < ActiveSupport::TestCase

  test 'user is populated correctly' do
    user = FactoryBot.build(:user)
    assert_equal 'john.doe@gmail.com', user.email, 'email not populated correctly'
    assert_equal 'john.doe', user.username, 'username not populated correctly'
  end
end
