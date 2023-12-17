class GitHookSetting < ActiveRecord::Base
  validates_presence_of :title

  validate :valid_action

  #------------------------------
  # 指摘チケットのトラッカー（ラベル）
  #------------------------------
  def remark_issue_tracker_label
    if remark_issue_tracker.nil?
      ""
    else
      temp = Tracker.find_by(id: remark_issue_tracker)
      temp.nil? ? "" : temp.name
    end
  end

  #------------------------------
  # 指摘チケットの終了時のステータス（ラベル）
  #------------------------------
  def remark_issue_closed_status_label
    if remark_issue_closed_status.nil?
      ""
    else
      temp = IssueStatus.find_by(id: remark_issue_closed_status)
      temp.nil? ? "" : temp.name
    end
  end

  def available?
    is_enabled 
  end

  def valid_action

    # プロジェクトパターンが設定されていた場合
    if project_pattern.present?
      begin
        Regexp.compile(project_pattern)
      rescue
        errors.add(:project_pattern, :invalid)
      end
    end

    # 一連の指摘の終了を表すためのキーワードは必ず設定されていなければならない
    if !keyword_to_resolve_discussion.present? || keyword_to_resolve_discussion.empty?
      errors.add(:keyword_to_resolve_discussion, :invalid)
    end

  end

end
