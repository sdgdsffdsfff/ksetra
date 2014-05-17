load_env do |host|
  namespace host.name do
    namespace :web do

      desc "初始化设置服务器[#{host.name}]"
      task :setup do
        host.execute [
                         sudo("mkdir -p #{host.deploy_to}"),
                         sudo("chown #{host.user}:#{host.user} #{host.deploy_to}"),
                         "mkdir -p #{host.deploy_to}/releases",
                         "git clone #{host.repository} #{host.deploy_to}/scm"
                     ]

      end

      desc "上传共享目录到服务器[#{host.name}]"
      task :upload do
        host.upload "config/#{host.name}/shared", "#{host.deploy_to}"
      end

      desc "清理服务器[#{host.name}]"
      task :destroy do
        confirm('将会清理所有部署数据，确认要继续么', -> { host.execute ["rm -r #{host.deploy_to}"] })
      end

      desc "部署服务器[#{host.name}]"
      task :deploy do
        release = "#{host.deploy_to}/releases/v#{Time.now.strftime '%Y%m%d%H%M%S%L'}"

        clean_f = -> { host.execute ["rm -r #{release}"] }

        commands = [
            "cd #{host.deploy_to}/scm && git pull",
            "mkdir -p #{release}",
            "cp -a #{host.deploy_to}/scm/* #{release}",
        ]
        host.shared_paths.each { |p| commands << "ln -sv #{host.deploy_to}/shared/#{p} #{release}/#{p}" }
        commands += rbenv
        commands << "cd #{release} && bundle install"
        commands << "echo NEW VERSION: $(basename #{release})"
        host.execute commands

        confirm('版本更新成功，要继续么', -> {
          commands = rbenv
          commands << "cd #{release} && RAILS_ENV=production rake assets:precompile"
          commands << "cd #{release} && RAILS_ENV=production rake db:migrate"
          commands << puma_start(release)
          host.execute commands
          confirm('启动成功，要继续么', -> {
            current = "#{host.deploy_to}/releases/current"
            commands = [path?(current, puma_stop(current)<<"rm #{current}")]
            commands << "ln -sv #{release} #{current}"
            host.execute commands
          }, -> {
            host.execute
            clean_f.call
          })
        }, clean_f)
      end

      def puma_start(path)
        "cd #{path} && puma -b 'unix://#{path}/tmp/web.sock' --pidfile #{path}/tmp/web.pid -e production -d config.ru"
      end

      def puma_stop(path)
        [
            "kill -s SIGTERM  $(cat #{path}/tmp/web.pid)",
            "rm #{path}/tmp/web.pid",
            "rm #{path}/tmp/web.sock"
        ]
      end

      desc "列出服务器[#{host.name}]上最近可运行的版本"
      task :versions, :count do |_, args|
        args.with_defaults count: 7
        count = args[:count]
        cmd = "ls #{host.deploy_to}/releases | tail -n #{count}"
        host.execute [cmd]
      end

      desc "服务器[#{host.name}]WEB服务状态"
      task :status do
        cmd = <<BASH
for i in $(find /var/www/auth.0-dong.com/releases/v* -name *.sock) ; do
  basename $(dirname $(dirname $i))
done
BASH
        host.execute [cmd]
      end

    end
  end
end
