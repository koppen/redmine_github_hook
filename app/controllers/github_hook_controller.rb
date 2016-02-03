require "json"

class GithubHookController < ApplicationController
  before_filter :check_enabled
  skip_before_filter :verify_authenticity_token, :check_if_login_required

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

  def check_enabled
    User.current = nil
    unless Setting.sys_api_enabled? && (Setting.sys_api_key.empty? || params[:key].to_s == Setting.sys_api_key)
      render :text => 'Access denied. Repository management WS is disabled or key is invalid.', :status => 403
      return false
    end
  end
end
