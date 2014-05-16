load_env do |host|
  namespace host.name do
    namespace :system do

      desc "服务器[#{host.name}]当前状态"
      task :status do
        host.execute ['uname -a']
      end

    end
  end
end

