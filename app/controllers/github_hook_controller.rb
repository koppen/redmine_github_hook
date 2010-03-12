require 'json'
require 'open3'

class GithubHookController < ApplicationController

  skip_before_filter :verify_authenticity_token, :check_if_login_required

  def index
    repository = find_repository

    # Fetch the changes from Github
    update_repository(repository)

    # Fetch the new changesets into Redmine
    repository.fetch_changesets

    render(:text => 'OK')
  end

  private

  def exec(command)
    logger.debug { "GithubHook: Executing command: '#{command}'" }
    stdin, stdout, stderr = Open3.popen3(command)

    output = stdout.readlines.collect(&:strip)
    errors = stderr.readlines.collect(&:strip)

    logger.debug { "GithubHook: Output from git:" }
    logger.debug { "GithubHook:  * STDOUT: #{output}"}
    logger.debug { "GithubHook:  * STDERR: #{output}"}
  end

  # Fetches updates from the remote repository
  def update_repository(repository)
    command = "cd '#{repository.url}' && git fetch origin && git reset --soft refs/remotes/origin/master"
    exec(command)
  end

  # Gets the project identifier from the querystring parameters and if that's not supplied, assume
  # the Github repository name is the same as the project identifier.
  def get_identifier
    payload = JSON.parse(params[:payload])
    identifier = params[:project_id] || payload['repository']['name']
    raise ActiveRecord::RecordNotFound, "Project identifier not specified" if identifier.nil?
    return identifier
  end

  # Finds the Redmine project in the database based on the given project identifier
  def find_project
    identifier = get_identifier
    project = Project.find_by_identifier(identifier.downcase)
    raise ActiveRecord::RecordNotFound, "No project found with identifier '#{identifier}'" if project.nil?
    return project
  end

  # Returns the Redmine Repository object we are trying to update
  def find_repository
    project = find_project
    repository = project.repository
    raise TypeError, "Project '#{project.to_s}' ('#{project.identifier}') has no repository" if repository.nil?
    raise TypeError, "Repository for project '#{project.to_s}' ('#{project.identifier}') is not a Git repository" unless repository.is_a?(Repository::Git)
    return repository
  end

end
