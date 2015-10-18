module GithubHook
  class NullLogger
    def debug(*_); end

    def info(*_); end

    def warn(*_); end

    def error(*_); end
  end
end
