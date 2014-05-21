load_env do |host|
  if host.repository.start_with?('git@github.com:chonglou/')
    namespace host.name do
      desc "在服务器#{host.name}上运行rake命令"
      task :run, :cmd do |_, args|
        cmd = args[:cmd]
        if cmd
          host.execute rbenv(host.env)<<"cd #{host.deploy_to}/releases/current && rake #{cmd}"
        else
          puts '无操作'
        end
      end

      namespace :web do
        desc "更新服务器#{host.name}3rd资源"
        task '3rd' do
          tmp = '/tmp/brahma'
          commands = []
          commands << path?("#{tmp}/3rd", [
              "cd #{tmp}/3rd && git pull"
          ], [
                                "git clone git@github.com:chonglou/3rd.git #{tmp}/3rd"
                            ])
          path = "#{host.deploy_to}/releases/current/public/3rd"
          commands << path?(path, ["rm -r #{path}"])
          commands << "mkdir -p #{path}"
          commands << "cp -r #{tmp}/3rd/* #{path}"
          commands += rbenv(host.env)
          commands << "cd #{host.deploy_to}/releases/current && rake app:brahma:web:seo"
          host.execute commands
        end
      end
    end
  end

  namespace :brahma do

    desc '更新brahma公共库'
    task :upgrade do
      tmp = '/tmp/brahma'
      commands = []
      commands += rbenv host.env
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
      commands << "cd #{tmp}/bodhi && bundle install"
      commands << "cd #{tmp}/bodhi && rake install"

      commands << path?("#{tmp}/daemon", [
          "cd #{tmp}/daemon && git pull"
      ], [
                            "git clone git@github.com:chonglou/daemon.git #{tmp}/daemon"
                        ])
      commands << "cd #{tmp}/daemon && bundle install"
      commands << "cd #{tmp}/daemon && rake install"

      host.execute commands

    end
  end
end