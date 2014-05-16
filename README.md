Rails部署工具
======

没有趁手的，只好自己轮了

#### 用法
    cp config/servers.yml.tmp config/servers.yml
    vi servers.yml #添加配置文件
    rake -T #查看任务

#### Brahma项目部署 依赖
    apt-get install libmysqlclient-dev

## 常见问题

###  运行“rake brahma:upgrade”失败 原因：貌似ssh找不到一些环境变量
    cd /tmp/brahma/bodhi
    bundle install

