require 'json'

class GithubHookController < ApplicationController

  def index
    logger.debug { "---------------------------------" }
    payload = JSON.parse(params[:payload])
    logger.debug { "Received from Github: #{payload.inspect}" }

    logger.debug { "Finding project" }
    # For now, we assume that the repository name is the same as the project identifier
    project = Project.find_by_identifier(payload['repository']['name'])
    raise ActiveRecord::RecordNotFound if project.nil? || project.repository.nil?
    
    logger.debug { "Finding repo" }
    repository = project.repository
    raise TypeError unless repository.is_a?(Repository::Git)

    # Get updates from the Github repository
    command = "cd '#{repository.url}' && git pull"
    exec(command)

    render(:text => 'OK')
  end

  private
  
  def exec(command)
    logger.debug { "GitHook: Executing command: '#{command}'" }
    `#{command}`
  end

end
