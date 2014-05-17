Rails部署工具
======

没有趁手的，只好自己轮了

#### 用法
    cp config/servers.yml.tmp config/servers.yml
    vi servers.yml #添加配置文件
    rake -T #查看任务

#### Brahma项目部署 依赖
    apt-get install libmysqlclient-dev pwgen

## 常见问题

### git ssh 证书问题
 * 由于第一次连接github，会提示接受证书 需要上服务器上先随便clone一下

### bundle install失败
 * 由于gem版本冲突，需要运行bundle update
