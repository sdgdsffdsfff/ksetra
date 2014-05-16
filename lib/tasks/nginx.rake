load_env do |host|
  namespace host.name do

    desc "在服务器[#{host.name}]上的nginx配置文件样例"
    task :nginx do
      confirm('启用SSL', ->{
        puts <<FILE
    server {
        listen       443;
        server_name  #{host.domain};
        ssl                  on;
        ssl_certificate      cert/#{host.domain}-cert.pem;
        ssl_certificate_key  cert/#{host.domain}-key.pem;
        #{confirm('双向验证', ->{'ssl_client_certificate cert/root-cert.pem;'})}
        ssl_session_timeout  20m;
        ssl_verify_client on;
        ssl_protocols  SSLv2 SSLv3 TLSv1;
        ssl_ciphers  RC4:HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers   on;

        root   #{host.deploy_to}/releases/current/public;

        location / {
          proxy_pass unix://#{host.deploy_to}/releases/current/tmp/web.sock;
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
FILE
      }, ->{
        puts <<FILE
    server {
        listen       80;
        server_name  #{host.domain};

        root   #{host.deploy_to}/releases/current/public;

        location / {
          proxy_pass unix://#{host.deploy_to}/releases/current/tmp/web.sock;
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
FILE
      })
    end
  end
end
