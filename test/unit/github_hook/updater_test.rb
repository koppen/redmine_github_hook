require "test_helper"

require "minitest"
require "mocha"

class GithubHookUpdaterTest < MiniTest::Unit::TestCase
  def project
    return @project if @project

    @project ||= Project.new
    @project.repositories << repository
    @project
  end

  def repository
    return @repository if @repository

    @repository ||= Repository::Git.new(:identifier => "redmine")
    @repository.stubs(:fetch_changesets).returns(true)
    @repository
  end

  # rubocop:disable Metrics/LineLength
  def payload
    # Ruby hash with the parsed data from the JSON payload
    {
      "before" => "5aef35982fb2d34e9d9d4502f6ede1072793222d",
      "repository" => {"url" => "http://github.com/defunkt/github", "name" => "github", "description" => "You're lookin' at it.", "watchers" => 5, "forks" => 2, "private" => 1, "owner" => {"email" => "chris@ozmm.org", "name" => "defunkt"}},
      "commits" => [
        {"id" => "41a212ee83ca127e3c8cf465891ab7216a705f59", "url" => "http://github.com/defunkt/github/commit/41a212ee83ca127e3c8cf465891ab7216a705f59", "author" => {"email" => "chris@ozmm.org", "name" => "Chris Wanstrath"}, "message" => "okay i give in", "timestamp" => "2008-02-15T14:57:17-08:00", "added" => ["filepath.rb"]},
        {"id" => "de8251ff97ee194a289832576287d6f8ad74e3d0", "url" => "http://github.com/defunkt/github/commit/de8251ff97ee194a289832576287d6f8ad74e3d0", "author" => {"email" => "chris@ozmm.org", "name" => "Chris Wanstrath"}, "message" => "update pricing a tad", "timestamp" => "2008-02-15T14:36:34-08:00"}
      ],
      "after" => "de8251ff97ee194a289832576287d6f8ad74e3d0",
      "ref" => "refs/heads/master"
    }
  end
  # rubocop:enable Metrics/LineLength

  def build_updater(payload, options = {})
    updater = GithubHook::Updater.new(payload, options)
    updater.stubs(:exec).returns(true)
    updater
  end

  def updater
    return @memoized_updater if @memoized_updater
    @memoized_updater = build_updater(payload)
  end

  def setup
    Project.stubs(:find_by_identifier).with("github").returns(project)

    # Make sure we don't run actual commands in test
    GithubHook::Updater.any_instance.expects(:system).never
    Repository.expects(:fetch_changesets).never
  end

  def teardown
    @memoized_updater = nil
  end

  def test_uses_repository_name_as_project_identifier
    Project.expects(:find_by_identifier).with("github").returns(project)
    updater.call
  end

  def test_fetches_changes_from_origin
    updater.expects(:exec).with("git fetch origin", repository.url)
    updater.call
  end

  def test_resets_repository_when_fetch_origin_succeeds
    updater
      .expects(:exec)
      .with("git fetch origin", repository.url)
      .returns(true)
    updater
      .expects(:exec)
      .with(
        "git fetch --prune origin \"+refs/heads/*:refs/heads/*\"",
        repository.url
      )
    updater.call
  end

  def test_resets_repository_when_fetch_origin_fails
    updater
      .expects(:exec)
      .with("git fetch origin", repository.url)
      .returns(false)
    updater
      .expects(:exec)
      .with("git reset --soft refs\/remotes\/origin\/master", repository.url)
      .never
    updater.call
  end

  def test_uses_project_identifier_from_request
    Project.expects(:find_by_identifier).with("redmine").returns(project)
    updater = build_updater(payload, :project_id => "redmine")
    updater.call
  end

  def test_updates_all_repositories_by_default
    another_repository = Repository::Git.new
    another_repository.expects(:fetch_changesets).returns(true)
    project.repositories << another_repository

    updater = build_updater(payload)
    updater.expects(:exec).with("git fetch origin", repository.url)
    updater.call
  end

  def test_updates_only_the_specified_repository
    another_repository = Repository::Git.new
    another_repository.expects(:fetch_changesets).never
    project.repositories << another_repository

    updater = build_updater(payload, :repository_id => "redmine")
    updater.expects(:exec).with("git fetch origin", repository.url)
    updater.call
  end

  def test_updates_all_repositories_if_specific_repository_is_not_found
    another_repository = Repository::Git.new
    another_repository.expects(:fetch_changesets).returns(true)
    project.repositories << another_repository

    updater = build_updater(payload, :repository_id => "redmine or something")
    updater.expects(:exec).with("git fetch origin", repository.url)
    updater.call
  end

  def test_raises_record_not_found_if_project_identifier_not_found
    assert_raises ActiveRecord::RecordNotFound do
      updater = build_updater({})
      updater.call
    end
  end

  def test_raises_record_not_found_if_project_identifier_not_given
    assert_raises ActiveRecord::RecordNotFound do
      updater = build_updater(payload.merge("repository" => {}))
      updater.call
    end
  end

  def test_raises_record_not_found_if_project_not_found
    assert_raises ActiveRecord::RecordNotFound do
      Project.expects(:find_by_identifier).with("foobar").returns(nil)
      updater = build_updater(payload, :project_id => "foobar")
      updater.call
    end
  end

  def test_downcases_identifier
    # Redmine project identifiers are always downcase
    Project.expects(:find_by_identifier).with("redmine").returns(project)
    updater = build_updater(payload, :project_id => "ReDmInE")
    updater.call
  end

  def test_fetches_changesets_into_the_repository
    updater.expects(:update_repository).returns(true)
    repository.expects(:fetch_changesets).returns(true)
    updater.call
  end

  def test_raises_type_error_if_project_has_no_repository
    assert_raises TypeError do
      project = mock("project", :to_s => "My Project", :identifier => "github")
      project.expects(:repositories).returns([])
      Project.expects(:find_by_identifier).with("github").returns(project)
      updater.call
    end
  end

  def test_raises_type_error_if_repository_is_not_git
    assert_raises TypeError do
      project = mock("project", :to_s => "My Project", :identifier => "github")
      repository = Repository::Subversion.new
      project.expects(:repositories).at_least(1).returns([repository])
      Project.expects(:find_by_identifier).with("github").returns(project)
      updater.call
    end
  end

  def test_logs_if_a_logger_is_given
    updater = GithubHook::Updater.new(payload)
    updater.stubs(:exec).returns(true)

    logger = stub("Logger")
    logger.expects(:info).at_least_once
    updater.logger = logger

    updater.call
  end

  def test_logs_if_a_message_logger_is_given
    updater = GithubHook::Updater.new(payload)
    updater.stubs(:exec).returns(true)

    logger = GithubHook::MessageLogger.new
    updater.logger = logger

    updater.call
    assert logger.messages.any?, "Should have received messages"
  end
end
