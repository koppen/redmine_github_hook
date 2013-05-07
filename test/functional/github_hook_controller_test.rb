require 'test_helper'

require 'test/unit'
require 'mocha'

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
    Project.stubs(:find_by_identifier).with('github').returns(project)

    # Make sure we don't run actual commands in test
    @controller.expects(:system).never
    Repository.expects(:fetch_changesets).never
  end

  def mock_descriptor(kind, contents = [])
    descriptor = mock(kind)
    descriptor.expects(:readlines).returns(contents)
    descriptor
  end

  def do_post(payload = nil)
    payload = json if payload.nil?
    payload = payload.to_json if payload.is_a?(Hash)
    post :index, :payload => payload
  end

  def test_should_use_the_repository_name_as_project_identifier
    Project.expects(:find_by_identifier).with('github').returns(project)
    @controller.stubs(:exec).returns(true)
    do_post
  end

  def test_should_fetch_changes_from_origin
    Project.expects(:find_by_identifier).with('github').returns(project)
    @controller.expects(:exec).with("git --git-dir='#{repository.url}' fetch origin")
    do_post
  end

  def test_should_reset_repository_when_fetch_origin_succeeds
    Project.expects(:find_by_identifier).with('github').returns(project)
    @controller.expects(:exec).with("git --git-dir='#{repository.url}' fetch origin").returns(true)
    @controller.expects(:exec).with("git --git-dir='#{repository.url}' fetch origin '+refs/heads/*:refs/heads/*'")
    do_post
  end

  def test_should_not_reset_repository_when_fetch_origin_fails
    Project.expects(:find_by_identifier).with('github').returns(project)
    @controller.expects(:exec).with("git --git-dir='#{repository.url}' fetch origin").returns(false)
    @controller.expects(:exec).with("git --git-dir='#{repository.url}' reset --soft refs\/remotes\/origin\/master").never
    do_post
  end

  def test_should_use_project_identifier_from_request
    Project.expects(:find_by_identifier).with('redmine').returns(project)
    @controller.stubs(:exec).returns(true)
    post :index, :project_id => 'redmine', :payload => json
  end

  def test_should_downcase_identifier
    # Redmine project identifiers are always downcase
    Project.expects(:find_by_identifier).with('redmine').returns(project)
    @controller.stubs(:exec).returns(true)
    post :index, :project_id => 'ReDmInE', :payload => json
  end

  def test_should_render_ok_when_done
    @controller.expects(:update_repository).returns(true)
    do_post
    assert_response :success
    assert_equal 'OK', @response.body
  end

  def test_should_fetch_changesets_into_the_repository
    @controller.expects(:update_repository).returns(true)
    repository.expects(:fetch_changesets).returns(true)

    do_post
    assert_response :success
    assert_equal 'OK', @response.body
  end

  def test_should_return_404_if_project_identifier_not_given
    assert_raises ActiveRecord::RecordNotFound do
      do_post :repository => {}
    end
  end

  def test_should_return_404_if_project_not_found
    assert_raises ActiveRecord::RecordNotFound do
      Project.expects(:find_by_identifier).with('foobar').returns(nil)
      do_post :repository => {:name => 'foobar'}
    end
  end

  def test_should_return_500_if_project_has_no_repository
    assert_raises TypeError do
      project = mock('project', :to_s => 'My Project', :identifier => 'github')
      project.expects(:repositories).returns([])
      Project.expects(:find_by_identifier).with('github').returns(project)
      do_post :repository => {:name => 'github'}
    end
  end

  def test_should_return_500_if_repository_is_not_git
    assert_raises TypeError do
      project = mock('project', :to_s => 'My Project', :identifier => 'github')
      repository = Repository::Subversion.new
      project.expects(:repositories).at_least(1).returns([repository])
      Project.expects(:find_by_identifier).with('github').returns(project)
      do_post :repository => {:name => 'github'}
    end
  end

  def test_should_not_require_login
    @controller.expects(:update_repository).returns(true)
    @controller.expects(:check_if_login_required).never
    do_post
  end

  def test_exec_should_log_output_from_git_as_debug_when_things_go_well
    @controller.expects(:system).at_least(1).returns(true)
    @controller.logger.expects(:debug).at_least(1)
    do_post
  end

  def test_exec_should_log_output_from_git_as_error_when_things_go_sour
    @controller.expects(:system).at_least(1).returns(false)
    @controller.logger.expects(:error).at_least(1)
    do_post
  end

  def test_should_respond_to_get
    get :index
    assert_response :success
  end

end
