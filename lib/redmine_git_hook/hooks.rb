module RedmineGitHook
  class Hooks < Redmine::Hook::ViewListener

    # 全ビューのベースHTMLを作成時
    def view_layouts_base_html_head(context = { })
        stylesheet_link_tag('git_hook_setting.css', :plugin => 'redmine_git_hook')
    end

  end
end