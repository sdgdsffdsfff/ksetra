load_env do |host|
  if host.repository.start_with?('git@github.com:chonglou/')
    namespace host.name do

    end
  end

  namespace :brahma do

    desc '更新brahma公共库'
    task :upgrade do
      tmp = '/tmp/brahma'
      commands = []

      commands << path?("#{tmp}/3rd", [
          "cd #{tmp}/3rd && git pull"
      ], [
                            "git clone git@github.com:chonglou/3rd.git #{tmp}/3rd"
                        ])
      commands += rbenv
      commands << path?("#{tmp}/utils", [
          "cd #{tmp}/utils && git pull"
      ], [
                            "git clone git@github.com:chonglou/utils.git #{tmp}/utils"
                        ])
      commands << "cd #{tmp}/utils && bundle install"
      commands << "cd #{tmp}/utils && rake install"

      commands << path?("#{tmp}/bodhi", [
          "cd #{tmp}/bodhi && git pull"
      ], [
                            "git clone git@github.com:chonglou/bodhi.git #{tmp}/bodhi"
                        ])
      commands << "cd #{tmp}/utils && bundle install"
      commands << "cd #{tmp}/bodhi && rake install"

      host.execute commands

    end
  end
end