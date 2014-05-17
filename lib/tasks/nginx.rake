load_env do |host|
  namespace host.name do

    desc "在服务器[#{host.name}]上的nginx配置文件样例"
    task :nginx do
      port = 80
      ssl = []
      if yesno?('启用SSL')
        port = 443
        ssl = [
            'ssl  on;',
            "ssl_certificate  ssl/#{host.domain}-cert.pem;",
            "ssl_certificate_key  ssl/#{host.domain}-key.pem;",

        ]
        if yesno?('双向验证')
          ssl << 'ssl_verify_client on;'
          ssl << 'ssl_client_certificate ssl/root-cert.pem;'
        end
        ssl += [
            'ssl_session_timeout  5m;',
            'ssl_protocols  SSLv2 SSLv3 TLSv1;',
            'ssl_ciphers  RC4:HIGH:!aNULL:!MD5;',
            'ssl_prefer_server_ciphers  on;'
        ]
      end
      puts <<FILE
upstream #{host.name}_app {
  server unix://#{host.deploy_to}/releases/current/tmp/web.sock;
}
server {
  listen       #{port};
  server_name  #{host.domain};

  #{ssl.join "\n  "}

  root   #{host.deploy_to}/releases/current/public;

  location / {
    proxy_pass #{host.name}_app;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
}
FILE
    end
  end
end
