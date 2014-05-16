load_env do |host|
  namespace host.name do
    namespace :ruby do

      desc "在服务器[#{host.name}]上安装ruby"
      task :install, :version do |_, args|
        version = args[:version]
        if version
          commands = [path?('$HOME/.rbenv',
                            [
                                'cd ~/.rbenv && git pull',
                                'cd ~/.rbenv/plugins/ruby-build && git pull',
                            ],
                            [
                                'git clone https://github.com/sstephenson/rbenv.git ~/.rbenv',
                                'git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build'
                            ]
                      )]
          commands += rbenv
          commands << "rbenv install -f -v  #{version}"
          commands << "rbenv global #{version}"
          commands << 'rbenv rehash'
          commands << 'gem install bundler'
          host.execute commands
        else
          puts '需要指定版本号'
        end
      end

      desc "在服务器上#{host.name}上删除ruby"
      task :uninstall, :version do |_, args|
        version = args[:version]
        if version
          commands = rbenv
          commands << "rbenv uninstall -f #{version}"
          host.execute commands
        else
          puts '需要指定版本号'
        end
      end

      desc "显示服务器[#{host.name}]上ruby版本"
      task :versions do
        host.execute rbenv<< 'rbenv versions'
      end

    end

  end
end
