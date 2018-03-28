Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.

  devise_for :users

  root 'projects#index'

  resources :projects do
    member do
      post 'remove_all_base_images'
      post 'clean_base_image_state'
      post 'cleanup_uncommitted_builds'
      post 'base_images'
      get 'base_images'
      get 'base_images_test_images'
    end
  end

  resources :builds do
    member do
      get 'unapproved_diffs'
      get 'approved_diffs'
      get 'new_tests'
      get 'missing_tests'
      get 'successful_tests'
      post 'approve_all_images'
      post 'add_md5s'
      post 'commit'
      get 'commit'
      post 'fail'
    end
  end

  resources :diffs do
    member do
      post 'approve'
      post 'unapprove'
      post 'next'
      post 'multiple_diff_approval'
      post 'create_jira'
    end
  end

  resources :jiras

  resources :tests do
    member do
      post 'remove_base_images'
    end
  end

  resources :test_images

  resources :users do
    member do
      post 'show_authentication_token'
      post 'revoke_authentication_token'
    end
  end

  # Commontator stuff
  mount Commontator::Engine => '/commontator'
end
