FactoryBot.define do
  factory :build do
    url "#{SystemTestConfig.bamboo_base_url}/browse/ANDROIDGITHUBBUILD-ANDRGITHUBPULLREQUEST-26740"
    temporary false
    title 'ANDROIDGITHUBBUILD-ANDRGITHUBPULLREQUEST-26740'
    project_id 1
    commit_sha 'd3e552976815db44ac05983a817f7d1c333ef98e'
    pull_request_number 1704
    image_md5s '000000.png=>5d06899520fdbe8fccf6e83eb33998d0'
    username 'john.doe'
  end
end