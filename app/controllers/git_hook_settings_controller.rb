class GitHookSettingsController < ApplicationController
  layout 'admin'

  before_action :require_admin
  before_action :find_git_hook_setting, :except => [:index, :new, :create]

  helper :sort
  include SortHelper

  def index
    sort_init 'id', 'desc'
    sort_update %w(id path_pattern)
    @git_hook_settings = GitHookSetting.order(sort_clause)
  end

  def new
    @git_hook_setting = GitHookSetting.new
    # 001_create_git_hook_settings.rb で default が設定できなかったのでここで設定する
    @git_hook_setting.keyword_to_resolve_discussion = "!close!"
  end

  def create
    @git_hook_setting = GitHookSetting.new(git_hook_setting_params)
    @git_hook_setting.keyword_to_resolve_discussion = "!close!"

    if @git_hook_setting.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to git_hook_setting_path(@git_hook_setting.id)
    else
      render :action => 'new'
    end
  end

  def show
  end

  def edit
  end

  def update
    @git_hook_setting.attributes = git_hook_setting_params
    if @git_hook_setting.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to git_hook_setting_path(@git_hook_setting.id)
    else
      render :action => 'edit'
    end
  rescue ActiveRecord::StaleObjectError
    flash.now[:error] = l(:notice_locking_conflict)
    render :action => 'edit'
  end

  def update_all
    GitHookSetting.update_all(git_hook_setting_params.to_hash)

    flash[:notice] = l(:notice_successful_update)
    redirect_to git_hook_settings_path
  end

  def destroy
    @git_hook_setting.destroy
    redirect_to git_hook_settings_path
  end

  private

  def find_git_hook_setting
    @git_hook_setting = GitHookSetting.find(params[:id])
    render_404 unless @git_hook_setting
  end

  def git_hook_setting_params
    params.require(:git_hook_setting)
      .permit(
        :title, 
        :is_enabled,
        :project_pattern,
        :remark_issue_tracker,
        :remark_issue_closed_status,
        :keyword_to_resolve_discussion
      )
  end

end
