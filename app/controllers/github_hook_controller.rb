require "json"

class GithubHookController < ApplicationController
  skip_before_action :verify_authenticity_token, :check_if_login_required

  def index
    message_logger = GithubHook::MessageLogger.new(logger)
    update_repository(message_logger) if request.post?
    messages = message_logger.messages.map { |log| log[:message] }
    render(:json => messages)

  rescue ActiveRecord::RecordNotFound => error
    render_error_as_json(error, 404)

  rescue TypeError => error
    render_error_as_json(error, 412)
  end

  def welcome
    # Render the default layout
  end

  private

  def parse_payload
    JSON.parse(params[:payload] || "{}")
  end

  def render_error_as_json(error, status)
    render(
      :json => {
        :title => error.class.to_s,
        :message => error.message
      },
      :status => status
    )
  end

  def update_repository(logger)
    updater = GithubHook::Updater.new(parse_payload, params)
    updater.logger = logger
    updater.call
  end
end
