load_env do |host|
  namespace host.name do

    desc "在服务器[#{host.name}]上的nginx配置文件样例"
    task :nginx do
      port = 80
      ssl = nil
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
  server unix://#{host.deploy_to}/releases/current/tmp/web.sock fail_timeout=0;
}

server {
  listen #{port};
  server_name #{host.domain};

  #{ssl.join( "\n  ") if ssl}

  root #{host.deploy_to}/releases/current/public;
  try_files $uri/index.html $uri @#{host.name}_app;

  location ~* ^/(assets|3rd)/  {
    expires max;
    add_header  Cache-Control public;
  }

  location @#{host.name}_app {
    proxy_set_header  Host $http_host;
    proxy_set_header  X-Real-IP $remote_addr;
    proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
    #{'proxy_set_header  X-Forwarded-Proto https;' if ssl}
    proxy_redirect  off;
    proxy_pass http://#{host.name}_app;

  }
}
FILE
    end
  end
end
