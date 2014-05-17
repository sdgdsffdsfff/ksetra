load_env do |host|
  namespace host.name do
    namespace :ssl do
      desc "查看服务器[#{host.name}]上证书内容"
      task :cert?, :domain do |_, args|
        args.with_defaults domain: 'root'
        puts `openssl x509 -noout -text -in config/#{host.name}/ssl/#{args[:domain]}/cert.pem`
      end

      desc "检查服务器[#{host.name}]上KEY文件"
      task :verify?, :domain do |_, args|
        args.with_defaults domain: 'root'
        d = "config/#{host.name}/ssl"
        puts `openssl verify -CAfile #{d}/root/cert.pem #{d}/#{args[:domain]}/cert.pem`
      end

      desc "查看服务器[#{host.name}]KEY内容"
      task :key?, :domain do |_, args|
        args.with_defaults domain: 'root'
        puts `openssl rsa -noout -text -in config/#{host.name}/ssl/#{args[:domain]}/key.pem`
      end

      desc "服务器[#{host.name}]根证书制作"
      task :root do
        d = "config/#{host.name}/ssl/root"
        if Dir.exist?(d)
          puts '根证书目录已存在'
          next
        end
        require 'yaml'
        ssl = YAML.load(File.open "config/#{host.name}/ssl.yml")
        `mkdir -p #{d}`
        `openssl genrsa -out #{d}/key.pem 2048`
        `openssl req -new -key #{d}/key.pem -out #{d}/req.csr -text -subj "/C=#{ssl.fetch 'c'}/ST=#{ssl.fetch 'st'}/L=#{ssl.fetch 'l'}/O=#{ssl.fetch 'o'}/OU=#{ssl.fetch 'ou'}/CN=#{ssl.fetch 'cn'}/emailAddress=#{ssl.fetch 'email'}"`
        `openssl x509 -req -in #{d}/req.csr -out #{d}/cert.pem -sha512 -signkey #{d}/key.pem -days 3650 -text -extensions v3_ca`
      end

      desc "服务器[#{host.name}]子证书制作"
      task :child do
        root = "config/#{host.name}/ssl/root"
        unless Dir.exist?(root)
          puts '根证书不存在'
          next
        end

        require 'highline/import'
        domain = ask('子域') { |q| q.validate=/^[a-z0-9]{1,5}$/i }
        d = "config/#{host.name}/ssl/#{domain}"
        if Dir.exist?(d)
          puts '子域证书已存在'
          next
        end
        require 'yaml'
        ssl = YAML.load(File.open "config/#{host.name}/ssl.yml")
        `mkdir -p #{d}`
        `openssl genrsa -out #{d}/key.pem 2048`
        `openssl req -new -key #{d}/key.pem -out #{d}/req.csr -text -subj "/C=#{ssl.fetch 'c'}/ST=#{ssl.fetch 'st'}/L=#{ssl.fetch 'l'}/O=#{ssl.fetch 'o'}/OU=#{ssl.fetch 'ou'}/CN=#{domain}.#{ssl.fetch 'cn'}/emailAddress=#{ssl.fetch 'email'}"`
        `openssl x509 -req -in #{d}/req.csr -CA #{root}/cert.pem -CAkey #{root}/key.pem -CAcreateserial -days 3650 -out #{d}/cert.pem -text`
      end
    end
  end
end
