# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180326171851) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "builds", id: :serial, force: :cascade do |t|
    t.string "url"
    t.boolean "temporary", default: false
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "project_id"
    t.string "commit_sha"
    t.string "pull_request_number"
    t.integer "num_of_images_in_build", default: 0, null: false
    t.text "image_md5s"
    t.string "username", default: "Pull Request"
    t.string "branch_name", default: "Branch"
    t.text "associated_commit_shas"
    t.text "full_list_of_image_md5s"
    t.string "failure_message"
    t.boolean "dev_build", default: false
    t.index ["project_id"], name: "index_builds_on_project_id"
  end

  create_table "builds_base_images", id: :serial, force: :cascade do |t|
    t.integer "build_id"
    t.integer "test_image_id"
    t.index ["build_id"], name: "index_builds_base_images_on_build_id"
    t.index ["test_image_id"], name: "index_builds_base_images_on_test_image_id"
  end

  create_table "builds_successful_tests", id: :serial, force: :cascade do |t|
    t.integer "build_id"
    t.integer "test_image_id"
    t.index ["build_id"], name: "index_builds_successful_tests_on_build_id"
    t.index ["test_image_id"], name: "index_builds_successful_tests_on_test_image_id"
  end

  create_table "commontator_comments", id: :serial, force: :cascade do |t|
    t.string "creator_type"
    t.integer "creator_id"
    t.string "editor_type"
    t.integer "editor_id"
    t.integer "thread_id", null: false
    t.text "body", null: false
    t.datetime "deleted_at"
    t.integer "cached_votes_up", default: 0
    t.integer "cached_votes_down", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["cached_votes_down"], name: "index_commontator_comments_on_cached_votes_down"
    t.index ["cached_votes_up"], name: "index_commontator_comments_on_cached_votes_up"
    t.index ["creator_id", "creator_type", "thread_id"], name: "index_commontator_comments_on_c_id_and_c_type_and_t_id"
    t.index ["thread_id", "created_at"], name: "index_commontator_comments_on_thread_id_and_created_at"
  end

  create_table "commontator_subscriptions", id: :serial, force: :cascade do |t|
    t.string "subscriber_type", null: false
    t.integer "subscriber_id", null: false
    t.integer "thread_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["subscriber_id", "subscriber_type", "thread_id"], name: "index_commontator_subscriptions_on_s_id_and_s_type_and_t_id", unique: true
    t.index ["thread_id"], name: "index_commontator_subscriptions_on_thread_id"
  end

  create_table "commontator_threads", id: :serial, force: :cascade do |t|
    t.string "commontable_type"
    t.integer "commontable_id"
    t.datetime "closed_at"
    t.string "closer_type"
    t.integer "closer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["commontable_id", "commontable_type"], name: "index_commontator_threads_on_c_id_and_c_type", unique: true
  end

  create_table "diffs", id: :serial, force: :cascade do |t|
    t.integer "old_image_id"
    t.integer "new_image_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "differences_file_name"
    t.string "differences_content_type"
    t.integer "differences_file_size"
    t.datetime "differences_updated_at"
    t.integer "build_id"
    t.integer "approved_by_id"
    t.boolean "approved", default: false
    t.index ["approved_by_id"], name: "index_diffs_on_approved_by_id"
    t.index ["build_id"], name: "index_diffs_on_build_id"
    t.index ["new_image_id"], name: "index_diffs_on_new_image_id"
    t.index ["old_image_id"], name: "index_diffs_on_old_image_id"
  end

  create_table "jiras", id: :serial, force: :cascade do |t|
    t.string "title"
    t.string "project"
    t.string "component"
    t.string "description"
    t.string "issue_type"
    t.string "jira_link"
    t.string "jira_key"
    t.integer "diff_id"
    t.string "assignee"
    t.string "priority"
    t.string "jira_base_url"
    t.index ["diff_id"], name: "index_jiras_on_diff_id"
  end

  create_table "projects", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "github_root_url"
    t.string "github_repo"
    t.string "github_status_context", default: "continuous-integration/vizzy"
    t.jsonb "plugin_settings", default: {}, null: false
    t.string "vizzy_server_url"
    t.index ["plugin_settings"], name: "index_projects_on_plugin_settings", using: :gin
  end

  create_table "test_images", id: :serial, force: :cascade do |t|
    t.string "image_file_name"
    t.string "image_content_type"
    t.integer "image_file_size"
    t.datetime "image_updated_at"
    t.string "branch"
    t.boolean "approved", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "build_id"
    t.integer "test_id"
    t.boolean "user_approved_this_build", default: false
    t.boolean "image_created_this_build", default: false
    t.string "image_pull_request_sha"
    t.string "image_pull_request_number"
    t.string "md5"
    t.string "test_key"
    t.index ["build_id"], name: "index_test_images_on_build_id"
    t.index ["test_id"], name: "index_test_images_on_test_id"
  end

  create_table "tests", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "comment"
    t.string "jira"
    t.string "pull_request_link"
    t.string "comment_user"
    t.string "ancestry"
    t.string "ancestry_key"
    t.integer "project_id"
    t.index ["ancestry"], name: "index_tests_on_ancestry"
    t.index ["project_id"], name: "index_tests_on_project_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false
    t.string "username"
    t.string "authentication_token", limit: 30
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "tests", "projects", on_delete: :cascade
end
