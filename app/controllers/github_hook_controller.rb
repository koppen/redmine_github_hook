class GithubHookController < ApplicationController

  def index
    # For now, we assume that the repository name is the same as the project identifier
    project = Project.find_by_identifier(params[:repository][:name])
    raise ActiveRecord::RecordNotFound if project.nil? || project.repository.nil?
    
    repository = project.repository
    raise TypeError unless repository.is_a?(Repository::Git)

    # Get updates from the Github repository
    command = "cd '#{repository.url}' && git pull"
    exec(command)
  end

  private
  
  def exec(command)
    logger.debug { "GitHook: Executing command: '#{command}'" }
    `#{command}`
  end

end
