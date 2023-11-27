BUILD_DIR:=/home/isucon/webapp/go
BIN_NAME:=isupipe
SVC_NAME_SUFFIX:=-go

.PHONY: release
release: app-cp build

.PHONY: app-cp
app-cp:
	cp -fr ./webapp ~/

.PHONY: build
build:
	cd $(BUILD_DIR); \
	go build -o $(BIN_NAME)
	sudo systemctl restart $(BIN_NAME)${SVC_NAME_SUFFIX}.service

.PHONY: restart
restart:
	sudo systemctl restart $(BIN_NAME)${SVC_NAME_SUFFIX}.service

.PHONY: bench
bench:
	sudo touch /var/log/nginx/access.log
	sudo touch /tmp/mysql-slow.log
	sudo rm /var/log/nginx/access.log
	sudo rm /tmp/mysql-slow.log
	sudo systemctl restart nginx.service
	sudo systemctl restart mysql.service
	cd ~/isuumo/bench; \
	./bench -target-url http://127.0.0.1;
	sudo lshw -class processor | grep product | head -3;
	free -h

.PHONY: spec
spec:
	sudo lshw -class processor | grep product | head -3;
	free -h

.PHONY: pprof
pprof:
	cd $(BUILD_DIR); \
	go tool pprof -seconds 120 -http="0.0.0.0:1080" $(BIN_NAME) http://localhost:6060/debug/pprof/profile

.PHONY: pt-query
pt-query:
	cd /tmp; \
	sudo pt-query-digest --order-by Query_time:sum mysql-slow.log > ~/kataribe/pt-query-`date +%Y%m%d%H%M`.log

.PHONY: journal
journal:
	sudo journalctl -u ${BIN_NAME}${SVC_NAME_SUFFIX}.service | tail -n 100 | grep ERROR

.PHONY: kataribe
kataribe:
	cd ~; \
	mkdir -p kataribe; \
	sudo cat /var/log/nginx/access.log|~/go/bin/kataribe > ~/kataribe/kataribe-`date +%Y%m%d%H%M`.log

.PHONY: restart_nginx
restart_nginx:
	sudo systemctl restart nginx.service

.PHONY: restart_mysql
restart_mysql:
	sudo systemctl restart mysql

.PHONY: connect_mysql
connect_mysql:
	export MYSQL_PWD=isucon; \
	mysql -h 127.0.0.1 -P 3306 -u isucon $(BIN_NAME)

.PHONY: install_netdata
install_netdata:
	wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh && sh /tmp/netdata-kickstart.sh

.PHONY: install_pprof
install_pprof:
	go install runtime/pprof
	go install net/http/pprof
	echo 'セットアップ作業続きあり(pprof)'

.PHONY: install_pt_query_digest
install_pt_query_digest:
	sudo apt install percona-toolkit
	echo 'セットアップ作業続きあり(pt_query_digest)'
	echo '/etc/mysql/mysql.conf.d/mysqld.cnfに追記あり'
	
.PHONY: install_alp
install_alp:
	cd /tmp; \
	wget https://github.com/tkuchiki/alp/releases/download/v1.0.7/alp_linux_amd64.zip; \
	unzip /tmp/alp_linux_amd64.zip
	sudo install /tmp/alp /usr/local/bin
	echo 'セットアップ作業続きあり(alp)'

.PHONY: install_kataribe
install_kataribe:
	# go 1.16以降の手順になっている
	cd ~; \
	go install github.com/matsuu/kataribe@latest; \
	kataribe -generate

.PHONY: git_config
git_config:
	git config --global user.name serio
	git config --global user.email serio@serio.com

.PHONY: setup
#setup: install_netdata install_pprof install_pt_query_digest install_kataribe git_config
setup: install_kataribe git_config

.PHONY: keygen
keygen:
	ssh-keygen -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa <<< y;
	cat ~/.ssh/id_rsa.pub

.PHONY: install_graphviz
install_graphviz:
	sudo apt install -y graphviz