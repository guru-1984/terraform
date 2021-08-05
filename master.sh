#!/bin/sh
sudo apt-get update -y
sudo apt-get install openjdk-8-jdk openjdk-8-jre -y
chmod 777 /home/guru/.bashrc
sudo echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> /home/guru/.bashrc
sudo echo 'export PATH=/usr/lib/jvm/java-8-openjdk-amd64/bin:$PATH' >> /home/guru/.bashrc
#sudo chmod 777 /etc/environment
#sudo echo 'JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> /etc/environment
#sudo echo 'JRE_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre' >> /etc/environment
#wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
#sudo sh -c 'echo deb https://pkg.jenkins.io/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
wget -P /home/guru https://get.jenkins.io/war-stable/2.289.2/jenkins.war && java  -jar /home/guru/jenkins.war > /home/guru/jenkinoutpu &
#sudo apt-get update
#sudo apt-get install jenkins -y
