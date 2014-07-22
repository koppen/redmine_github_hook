require 'json'

class GithubHookController < ApplicationController
  skip_before_filter :verify_authenticity_token, :check_if_login_required

  def index
    if request.post?
      payload = JSON.parse(params[:payload] || '{}')
      updater = GithubHook::Updater.new(payload, params)
      updater.logger = logger
      updater.call
    end

    render(:text => 'OK')
  end

  def welcome
    # Render the default layout
  end
end
