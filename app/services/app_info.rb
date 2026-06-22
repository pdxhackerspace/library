module AppInfo
  module_function

  def version
    @version ||= begin
      ENV.fetch('APP_VERSION') { read_version_file }
    rescue Errno::ENOENT
      'dev'
    end
  end

  def github_repo_url
    @github_repo_url ||= build_github_repo_url
  end

  def github_repository
    ENV.fetch('GITHUB_REPOSITORY', nil).presence || detect_git_repository
  end

  def build_github_repo_url
    repository = github_repository
    return if repository.blank?

    "https://github.com/#{repository.sub(%r{\Ahttps?://github\.com/}, '').delete_suffix('.git')}"
  end

  def read_version_file
    Rails.root.join('VERSION').read.strip
  end

  def detect_git_repository
    remote = `git remote get-url origin 2>/dev/null`.strip
    return if remote.blank?

    parse_github_repository(remote)
  end

  def parse_github_repository(remote)
    if remote.start_with?('git@github.com:')
      remote.delete_prefix('git@github.com:').delete_suffix('.git')
    elsif remote.include?('github.com')
      URI.parse(remote).path.delete_prefix('/').delete_suffix('.git')
    end
  rescue URI::InvalidURIError
    nil
  end
end
