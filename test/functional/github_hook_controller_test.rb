require "test_helper"

require "minitest"
require "mocha"

class GithubHookControllerTest < ActionController::TestCase
  def json
    # Sample JSON post from http://github.com/guides/post-receive-hooks
    '{
      "before": "5aef35982fb2d34e9d9d4502f6ede1072793222d",
      "repository": {
        "url": "http://github.com/defunkt/github",
        "name": "github",
        "description": "You\'re lookin\' at it.",
        "watchers": 5,
        "forks": 2,
        "private": 1,
        "owner": {
          "email": "chris@ozmm.org",
          "name": "defunkt"
        }
      },
      "commits": [
        {
          "id": "41a212ee83ca127e3c8cf465891ab7216a705f59",
          "url": "http://github.com/defunkt/github/commit/41a212ee83ca127e3c8cf465891ab7216a705f59",
          "author": {
            "email": "chris@ozmm.org",
            "name": "Chris Wanstrath"
          },
          "message": "okay i give in",
          "timestamp": "2008-02-15T14:57:17-08:00",
          "added": ["filepath.rb"]
        },
        {
          "id": "de8251ff97ee194a289832576287d6f8ad74e3d0",
          "url": "http://github.com/defunkt/github/commit/de8251ff97ee194a289832576287d6f8ad74e3d0",
          "author": {
            "email": "chris@ozmm.org",
            "name": "Chris Wanstrath"
          },
          "message": "update pricing a tad",
          "timestamp": "2008-02-15T14:36:34-08:00"
        }
      ],
      "after": "de8251ff97ee194a289832576287d6f8ad74e3d0",
      "ref": "refs/heads/master"
    }'
  end

  def repository
    return @repository if @repository

    @repository ||= Repository::Git.new
    @repository.stubs(:fetch_changesets).returns(true)
    @repository
  end

  def project
    return @project if @project

    @project ||= Project.new
    @project.repositories << repository
    @project
  end

  def setup
    Setting.sys_api_enabled = '1'
    Setting.sys_api_key = 'my_secret_key'
    Project.stubs(:find_by_identifier).with("github").returns(project)

    # Make sure we don't run actual commands in test
    GithubHook::Updater.any_instance.expects(:system).never
    Repository.expects(:fetch_changesets).never
  end

  def teardown
    Setting.clear_cache
  end

  def do_post(key: 'my_secret_key')
    post :index, :payload => json, :key => key
  end

  def test_should_render_response_from_github_hook_when_done
    GithubHook::Updater.any_instance.expects(:update_repository).returns(true)
    do_post
    assert_response :success
    assert_match "GithubHook: Redmine repository updated", @response.body
  end

  def test_should_render_response_from_github_hook_when_done_with_empty_sys_api_key
    GithubHook::Updater.any_instance.expects(:update_repository).returns(true)
    with_settings :sys_api_key => '' do
      do_post :key => 'wrong_key'
    end
    assert_response :success
    assert_match "GithubHook: Redmine repository updated", @response.body
  end

  def test_disabled_ws_should_respond_with_403
    with_settings :sys_api_enabled => '0' do
      do_post
      assert_response 403
    end
  end

  def test_wrong_key_should_respond_with_403
    do_post :key => 'wrong_key'
    assert_response 403
  end

  def test_should_render_error_message
    GithubHook::Updater
      .any_instance
      .expects(:update_repository)
      .raises(ActiveRecord::RecordNotFound.new("Repository not found"))
    do_post
    assert_response :not_found
    assert_equal({
                   "title" => "ActiveRecord::RecordNotFound",
                   "message" => "Repository not found"
                 }, JSON.parse(@response.body))
  end

  def test_should_not_require_login
    GithubHook::Updater.any_instance.expects(:update_repository).returns(true)
    @controller.expects(:check_if_login_required).never
    do_post
  end

  def test_exec_should_log_output_from_git_as_debug_when_things_go_well
    GithubHook::Updater.any_instance.expects(:system).at_least(1).returns(true)
    @controller.logger.expects(:debug).at_least(1)
    do_post
  end

  def test_exec_should_log_output_from_git_as_error_when_things_go_sour
    GithubHook::Updater.any_instance.expects(:system).at_least(1).returns(false)
    @controller.logger.expects(:error).at_least(1)
    do_post
  end

  def test_should_respond_to_get
    get :index, :key => 'my_secret_key'
    assert_response :success
  end

  def test_wrong_key_should_respond_to_get_with_403
    get :index, :key => 'wrong_key'
    assert_response 403
  end
end
