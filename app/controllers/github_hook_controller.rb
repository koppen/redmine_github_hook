require 'json'

class GithubHookController < ApplicationController

  skip_before_filter :verify_authenticity_token, :check_if_login_required

  def index
    repositories = find_repositories

	repositories.each { |repository|
        # Fetch the changes from Github
        update_repository(repository)

        # Fetch the new changesets into Redmine
        repository.fetch_changesets
	}

    render(:text => 'OK')
  end

  private

  # Executes shell command. Returns true if the shell command exits with a success status code
  def exec(command)
    logger.debug { "GithubHook: Executing command: '#{command}'" }

    # Get a path to a temp file
    logfile = Tempfile.new('github_hook_exec')
    logfile.close

    success = system("#{command} > #{logfile.path} 2>&1")
    output_from_command = File.readlines(logfile.path)
    if success
      logger.debug { "GithubHook: Command output: #{output_from_command.inspect}"}
    else
      logger.error { "GithubHook: Command '#{command}' didn't exit properly. Full output: #{output_from_command.inspect}"}
    end

    return success
  ensure
    logfile.unlink
  end

  def git_command(command, repository)
    "git --git-dir='#{repository.url}' #{command}"
  end

  # Fetches updates from the remote repository
  def update_repository(repository)
    command = git_command('fetch origin', repository)
    if exec(command)
      command = git_command("fetch origin '+refs/heads/*:refs/heads/*'", repository)
      exec(command)
    end
  end

  # Gets the project identifier from the querystring parameters and if that's not supplied, assume
  # the Github repository name is the same as the project identifier.
  def get_identifier
    payload = JSON.parse(params[:payload] || '{}')
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

  # Returns the Redmine Repository objects we are trying to update
  def find_repositories
    project = find_project
    all_repositories = project.repositories
    payload = JSON.parse(params[:payload])
    raise TypeError, "Project '#{project.to_s}' ('#{project.identifier}') has no repositories" if all_repositories.empty?

    if params[:repository_id].present?
        repository = all_repositories.find_by_identifier_param(params[:repository_id])
        raise TypeError, "Project '#{project.to_s}' ('#{project.identifier}') has no repository with id #{params[:repository_id]}" if repository.nil?
        raise TypeError, "Repository '#{repository.identifier}' ('#{repository.id}') for project '#{project.to_s}' ('#{project.identifier}') is not a Git repository" unless repository.is_a?(Repository::Git)
        repositories = Array(repository)
    elsif params[:update_all]
        repositories = all_repositories.select { |repository| repository.is_a?(Repository::Git) }
        raise TypeError, "Project '#{project.to_s}' ('#{project.identifier}') has no Git repositories" if repositories.empty?
    else
        repository = project.repository
        raise TypeError, "Project '#{project.to_s}' ('#{project.identifier}') has no repository" if repository.nil?
        raise TypeError, "Default Repository for project '#{project.to_s}' ('#{project.identifier}') is not a Git repository" unless repository.is_a?(Repository::Git)
        repositories = Array(repository)
    end


    return repositories
  end
end
