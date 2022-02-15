#!/bin/bash


function ctrl_c(){
	echo -e "\n\n [!] Exiting...\n\n"
	exit 1
}

# Ctrl+c
trap ctrl_c INT

if [ "$(id -u)" == "0" ]; then
	echo -e "\n [+] Updating repositories..."
	apt update &>/dev/null
	echo -e "\n [+] Installing default version java..."
	apt install default-jdk -y &>/dev/null
	echo -e "\n [+] Adding username..."
	sudo useradd -m -d /opt/tomcat -U -s /bin/false tomcat
	echo -e "\n [+] Detecting wget in the system..."
	wget &>/dev/null
	if [ "$(echo $?)" == "1" ]; then
		echo -e "\n [+] Wget is in the system..."
	else
		echo -e "\n [+] Installing wget..."
		apt update &>/dev/null
		apt install wget &>/dev/null
	fi
	echo -e "\n Downloading Tomcat 10..."
	wget https://downloads.apache.org/tomcat/tomcat-10/v10.0.16/bin/apache-tomcat-10.0.16.tar.gz &>/dev/null
	echo -e "\n Decompressing file..."
	tar xzf apache-tomcat-10*tar.gz -C /opt/tomcat --strip-components=1 &>/dev/null
	echo -e "\n [+] You need to edit this files: /opt/tomcat/webapps/manager/META-INF/context.xml"
	echo -e "\n [+] And this: /opt/tomcat/webapps/host-manager/META-INF/context.xml"
	echo -e "\n [+] Comment the line contains the word 'Valve'"
	echo -e "\n [+] Creating Tomcat systemd Unit..."
	touch /etc/systemd/system/tomcat.service
	echo """[Unit]
	Description=Tomcat
	After=network.target

	[Service]
	Type=forking

	User=tomcat
	Group=tomcat

	Environment="JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64"
	Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"
	Environment="CATALINA_BASE=/opt/tomcat"
	Environment="CATALINA_HOME=/opt/tomcat"
	Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
	Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

	ExecStart=/opt/tomcat/bin/startup.sh
	ExecStop=/opt/tomcat/bin/shutdown.sh

	[Install]
	WantedBy=multi-user.target""" > /etc/systemd/system/tomcat.service
	echo -e "\n Reloading the daemon..."
	systemctl daemon-reload &>/dev/null
	systemctl start tomcat.service &>/dev/null
	systemctl enable tomcat.service &>/dev/null
	echo -e "Enabling firewall..."
	ufw enable
	ufw allow 8080/tcp &>/dev/null
	ufw allow 8443/tcp &>/dev/null
	ufw enable 80 &>/dev/null
	ufw enable 443 &>/dev/null

else
	echo -e "\n[!] You need execute this program with root user"
fi
