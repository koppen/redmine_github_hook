module GithubHook
  class Updater
    GIT_BIN = Redmine::Configuration['scm_git_command'] || "git"

    attr_writer :logger

    def initialize(payload, params = {})
      @payload = payload
      @params = params
    end

    def call
      logger.info { "  GithubHook: Received POST request from GitHub." }

      #write_debuglog
      prepare_email

      repositories = find_repositories

      repositories.each do |repository|
        tg1 = Time.now
        # Fetch the changes from Github
        update_repository(repository)
        tg2 = Time.now

        tr1 = Time.now
        # Fetch the new changesets into Redmine
        repository.fetch_changesets
        tr2 = Time.now

        logger.info { "  GithubHook: Redmine repository updated: #{repository.identifier} (Git: #{time_diff_milli(tg1,tg2)}ms, Redmine: #{time_diff_milli(tr1,tr2)}ms)" }
      end
    end

    private

    class NullLogger
      def debug(*_); end
      def info(*_); end
      def warn(*_); end
      def error(*_); end
    end

    attr_reader :params, :payload

    def write_debuglog()

      begin
        file = File.open("/tmp/github_mailer.json", "w")
        file.write(payload)
      rescue IOError => e
        # some error occured, directory not writable etc.
      ensure
        file.close unless file == nil
      end

    end

    def prepare_email()

      commitmsg = ""
      home = payload['repository']['full_name']
      branch = payload['ref']
      url =  payload['repository']['url']
      compare = payload['compare']

      forks = payload['repository']['forks']
      watchers = payload['repository']['watchers']
      issues = payload['repository']['open_issues']
      defbranch = payload['repository']['default_branch']

      logger.info { "  GithubHook: #{home} #{branch} #{url} #{compare}" }
      logger.info { "  GithubHook: #{forks} #{watchers} #{issues} #{defbranch}" }

      # parse commits
      payload['commits'].each do |item|

        commitmsg = "Commit: #{item['id']}\n#{item['url']}\nAuthor: #{item['author']['name']} <#{item['author']['email']}>\nDate: #{item['timestamp']}\n\nChanged Paths:\n----------------------\n"

        item['added'].each do |added|
          commitmsg = "#{commitmsg}A #{added}\n"
        end
        item['modified'].each do |mod|
          commitmsg = "#{commitmsg}M #{mod}\n"
        end
        item['removed'].each do |rem|
          commitmsg = "#{commitmsg}R #{rem}\n"
        end
        commitmsg = "#{commitmsg}\nLog Message:\n-------------------\n#{item['message']}\n"

      end

      logger.info { "  GithubHook: Commits: #{commitmsg}" }

      # create e-mail subject and body
      subject = "[#{home}] #{payload['commits'][0]['message']}"

      stats = "Project Statistics:\n-----------------------\nForks: #{forks}\nWatchers: #{watchers}\nOpen Issues: #{issues}\n\n"
      emailmsg = "Branch: #{branch}\nProject Home: #{url}\n#{commitmsg}\nCompare: #{compare}\n\n#{stats}\n"

      logger.info { "  GithubHook: Subject: #{subject}" }
      logger.info { "  GithubHook: Body   : #{emailmsg}" }

      send_email('ron@cyberjunky.nl, jesse.kerkhoven@gmail.com, ualex73@gmail.com, wouter@wolkers.nl', subject, emailmsg)

    end

    def send_email(to, subject, body)
      to = to
      subject = subject
      body = body
`mail -s "#{subject}" "#{to}" -aFrom:support@domotiga.nl<<EOM
#{body}
EOM`

    end

    # Executes shell command. Returns true if the shell command exits with a
    # success status code.
    #
    # If directory is given the current directory will be changed to that
    # directory before executing command.
    def exec(command, directory)
      logger.debug { "  GithubHook: Executing command: '#{command}'" }

      # Get a path to a temp file
      logfile = Tempfile.new('github_hook_exec')
      logfile.close

      full_command = "#{command} > #{logfile.path} 2>&1"
      success = if directory.present?
        Dir.chdir(directory) do
          system(full_command)
        end
      else
        system(full_command)
      end

      output_from_command = File.readlines(logfile.path)
      if success
        logger.debug { "  GithubHook: Command output: #{output_from_command.inspect}"}
      else
        logger.error { "  GithubHook: Command '#{command}' didn't exit properly. Full output: #{output_from_command.inspect}"}
      end

      return success
    ensure
      logfile.unlink if logfile && logfile.respond_to?(:unlink)
    end

    # Finds the Redmine project in the database based on the given project identifier
    def find_project
      identifier = get_identifier
      project = Project.find_by_identifier(identifier.downcase)
      raise ActiveRecord::RecordNotFound, "No project found with identifier '#{identifier}'" if project.nil?
      return project
    end

    # Returns the Redmine Repository object we are trying to update
    def find_repositories
      project = find_project
      repositories = project.repositories.select do |repo|
        repo.is_a?(Repository::Git)
      end

      if repositories.nil? or repositories.length == 0
        raise TypeError, "Project '#{project.to_s}' ('#{project.identifier}') has no repository"
      end

      # if a specific repository id is passed in url parameter "repository_id", then try to find it in
      # the list of current project repositories and use only this and not all to pull changes from
      # (issue #54)
      if params.has_key?(:repository_id)
        param_repo = repositories.select do |repo|
          repo.identifier == params[:repository_id]
        end

        if param_repo.nil? or param_repo.length == 0
          logger.info { "  GithubHook: The repository '#{params[:repository_id]}' isn't in the list of projects repos. Updating all repos instead." }

        else
          repositories = param_repo
        end
      end

      return repositories
    end

    # Gets the project identifier from the querystring parameters and if that's not supplied, assume
    # the Github repository name is the same as the project identifier.
    def get_identifier
      identifier = get_project_name
      raise ActiveRecord::RecordNotFound, "Project identifier not specified" if identifier.nil?
      return identifier
    end

    # Attempts to find the project name. It first looks in the params, then in the
    # payload if params[:project_id] isn't given.
    def get_project_name
      params[:project_id] || (payload['repository'] ? payload['repository']['name'] : nil)
    end

    def git_command(command)
      GIT_BIN + " #{command}"
    end

    def logger
      @logger || NullLogger.new
    end

    def system(command)
      Kernel.system(command)
    end

    def time_diff_milli(start, finish)
      ((finish - start) * 1000.0).round(1)
    end

    # Fetches updates from the remote repository
    def update_repository(repository)
      command = git_command('fetch origin')
      if exec(command, repository.url)
        command = git_command("fetch origin \"+refs/heads/*:refs/heads/*\"")
        exec(command, repository.url)
      end
    end

  end
end
