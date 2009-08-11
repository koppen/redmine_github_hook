require 'json'

class GithubHookController < ApplicationController

  def index
    payload = JSON.parse(params[:payload])
    logger.debug { "Received from Github: #{payload.inspect}" }

    # For now, we assume that the repository name is the same as the project identifier
    identifier = payload['repository']['name']

    project = Project.find_by_identifier(identifier)
    raise ActiveRecord::RecordNotFound, "No project found with identifier '#{identifier}'" if project.nil?
    
    repository = project.repository
    raise TypeError, "Project '#{identifier}' has no repository" if repository.nil?
    raise TypeError, "Repository for project '#{identifier}' is not a Git repository" unless repository.is_a?(Repository::Git)

    # Get updates from the Github repository
    command = "cd '#{repository.url}' && cd .. && git pull --rebase"
    exec(command)

    # Fetch the new changesets into Redmine
    repository.fetch_changesets

    render(:text => 'OK')
  end

  private
  
  def exec(command)
    logger.info { "GithubHook: Executing command: '#{command}'" }
    output = `#{command}`
    logger.info { "GithubHook: Shell returned '#{output}'" }
  end

end
