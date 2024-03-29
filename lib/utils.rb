require 'net/ssh'

def yesno?(message)
  require 'highline/import'
  ask("#{message}?(y/n)  ") { |q| q.default = 'n' } == 'y'
end

def confirm(message, yes=nil, no=nil)
  yesno?(message) ? (yes.call if yes) : (no.call if no)
end

def rbenv(env)
  ['export PATH=$HOME/.rbenv/bin:$PATH', 'eval "$(rbenv init -)"', "export RAILS_ENV=#{env}"]
end

def sudo(command, user='root', password=nil)
  if password
    <<-BASH
sudo -u #{user} #{command}<<EOF
#{password}
EOF;
    BASH
  else
    "sudo -u #{user} #{command}"
  end
end

def path?(dir, commands1=['echo NONE'], commands2=['echo NONE'])
  <<-BASH
if [ -d "#{dir}" ]
then
#{commands1.join "\n"}
else
#{commands2.join "\n"}
fi
  BASH
end

def file?(file, commands1=['echo NONE'], commands2=['echo NONE'])
  <<-BASH
if [ -f "#{file}" ]
then
#{commands1.join "\n"}
else
#{commands2.join "\n"}
fi
  BASH
end


class Host
  attr_reader :name, :domain, :repository, :deploy_to, :branch, :shared_paths, :user, :env

  def initialize(name, args)
    @name = name
    @domain = args.fetch('domain')
    @repository = args.fetch('repository')
    @deploy_to = args['deploy_to'] || "/var/www/#{domain}"
    @branch = args['branch'] || 'master'
    @shared_paths = args['shared_paths']||%w(config/database.yml log)
    @env = args['env'] || 'production'


    ssh = args.fetch('ssh')
    @ssh={
        user: ssh['user']||'root',
        host: ssh.fetch('host'),
        port: ssh.key?('port') ? ssh['port'].to_i : 22
    }
    @user = @ssh.fetch :user
  end

  def upload(from, to)
    exec "scp -r -P #{@ssh.fetch :port} #{from} #{@ssh.fetch :user}@#{@ssh.fetch :host}:#{to}"
  end

  def execute(commands)

    puts "CONNECT: #{@ssh.fetch :user}@#{@ssh.fetch :host}:#{@ssh.fetch :port}"
    puts "#{'#'*80}\n#{commands.join "\n"}\n#{'#'*80}"

    commands << 'exit' unless commands.last=='exit'
    Net::SSH.start(@ssh.fetch(:host), @ssh.fetch(:user), port: @ssh.fetch(:port)) do |ssh|
      session = ssh.open_channel do |channel|
        channel.exec 'bash -l' do |ch, success|
          fail '登录出错' unless success
          commands.each { |cmd| ch.send_data "#{cmd}\n" }
          ch.on_data { |_, data| puts "\e[34;1mSTDOUT\e[0m: #{data}" }
          ch.on_extended_data { |_, _, data| puts "\e[35;1mSTDERR\e[0m: #{data}" }
          ch.on_close { puts 'DONE' }
        end
      end
      session.wait
    end
  end

end
