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
  rescue ActiveRecord::RecordNotFound => error
    render_error_as_json(error, 404)
  rescue TypeError => error
    render_error_as_json(error, 412)
  end

  def welcome
    # Render the default layout
  end

  private

  def render_error_as_json(error, status)
    render(
      :json => {
        :title => error.class.to_s,
        :message => error.message
      },
      :status => status
    )
  end
end
