require 'test_helper'

class BuildTest < ActiveSupport::TestCase

  setup do
    @build = FactoryBot.create(:build)
  end

  test 'build is valid after creation' do
    assert @build.valid?
  end

  test 'build is populated correctly' do
    assert_equal "#{SystemTestConfig.bamboo_base_url}/browse/ANDROIDGITHUBBUILD-ANDRGITHUBPULLREQUEST-26740", @build.url, 'Url not populated correctly'
    assert_equal false, @build.temporary, 'temporary not populated correctly'
    assert_equal 'ANDROIDGITHUBBUILD-ANDRGITHUBPULLREQUEST-26740', @build.title, 'title not populated correctly'
    assert_equal 'd3e552976815db44ac05983a817f7d1c333ef98e', @build.commit_sha, 'commit_sha not populated correctly'
    assert_equal '1704', @build.pull_request_number, 'pull_request_number not populated correctly'
  end

end
