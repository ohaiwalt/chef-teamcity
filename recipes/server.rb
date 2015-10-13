#
# Cookbook Name:: chef-teamcity
# Recipe:: server
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

TEAMCITY_VERSION = node['teamcity']['version']
TEAMCITY_USERNAME = node['teamcity']['username']
TEAMCITY_SERVICE_NAME = node['teamcity']['service_name']
TEAMCITY_GROUP = node['teamcity']['group']
TEAMCITY_HOME_PATH = "/home/#{TEAMCITY_USERNAME}"
TEAMCITY_PATH = "/opt/TeamCity-#{TEAMCITY_VERSION}"
TEAMCITY_INIT_LOCATION = "/etc/init.d/#{TEAMCITY_SERVICE_NAME}"

TEAMCITY_SRC_PATH = "#{TEAMCITY_PATH}.tar.gz"
TEAMCITY_PID_FILE = "#{TEAMCITY_PATH}/logs/#{TEAMCITY_SERVICE_NAME}.pid"
TEAMCITY_DB_USERNAME = node['teamcity']['server']['database']['username']
TEAMCITY_DB_PASSWORD = node['teamcity']['server']['database']['password']
TEAMCITY_DB_CONNECTION_URL = node['teamcity']['server']['database']['connection_url']
TEAMCITY_SERVER_EXECUTABLE = "#{TEAMCITY_PATH}/TeamCity/bin/teamcity-server.sh"
TEAMCITY_BIN_PATH = "#{TEAMCITY_PATH}/TeamCity/bin"
TEAMCITY_DATA_PATH = "#{TEAMCITY_PATH}/.BuildServer"
TEAMCITY_LIB_PATH = "#{TEAMCITY_DATA_PATH}/lib"
TEAMCITY_JDBC_PATH = "#{TEAMCITY_LIB_PATH}/jdbc"
TEAMCITY_CONFIG_PATH = "#{TEAMCITY_DATA_PATH}/config"
TEAMCITY_BACKUP_PATH = "#{TEAMCITY_DATA_PATH}/backup"
TEAMCITY_DATABASE_PROPS_NAME = 'database.properties'
TEAMCITY_DATABASE_PROPS_PATH = "#{TEAMCITY_CONFIG_PATH}/#{TEAMCITY_DATABASE_PROPS_NAME}"
TEAMCITY_JAR_URI = node['teamcity']['server']['database']['jdbc_url']
TEAMCITY_BACKUP_FILE = node['teamcity']['server']['backup']
TEAMCITY_JAR_NAME = ::File.basename(URI.parse(TEAMCITY_JAR_URI).path)
TEAMCITY_JDBC_NAME = TEAMCITY_JAR_NAME.split('.')[0] + '.' + TEAMCITY_JAR_NAME.split('.')[1] + '.' + TEAMCITY_JAR_NAME.split('.')[2]


include_recipe 'chef-teamcity::default'
include_recipe 'mysqld::default'

bash 'create mysqldb' do
  user 'root'
  cwd '/tmp'
  code <<-EOH
    mysql -u #{TEAMCITY_DB_USERNAME} -p#{TEAMCITY_DB_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS #{node['teamcity']['server']['database']['name']};"
  EOH
end

remote_file TEAMCITY_SRC_PATH do
  source "http://download.jetbrains.com/teamcity/TeamCity-#{TEAMCITY_VERSION}.tar.gz"
  owner TEAMCITY_USERNAME
  group TEAMCITY_GROUP
  mode 0644
  not_if { ::File.exists?("#{TEAMCITY_PATH}") } 
end

tarball "#{TEAMCITY_SRC_PATH}" do
  destination "#{TEAMCITY_PATH}"
  owner TEAMCITY_USERNAME
  group TEAMCITY_GROUP
  umask 022
  action :extract
  not_if { ::File.exists?(TEAMCITY_PATH) }  
end

paths = [
  TEAMCITY_DATA_PATH,
  TEAMCITY_LIB_PATH,
  TEAMCITY_JDBC_PATH,
  TEAMCITY_CONFIG_PATH,
  TEAMCITY_BACKUP_PATH
]

paths.each do |p|
  directory p do
    owner TEAMCITY_USERNAME
    group TEAMCITY_GROUP
    recursive true
    mode 0755
  end
end

remote_file "#{TEAMCITY_JDBC_PATH}/#{TEAMCITY_JAR_NAME}" do
  source TEAMCITY_JAR_URI
  owner TEAMCITY_USERNAME
  group TEAMCITY_GROUP
  mode 0644
  not_if { ::File.exists?("#{TEAMCITY_JDBC_PATH}/#{TEAMCITY_JDBC_NAME}-bin.jar") } 
end

tarball "#{TEAMCITY_JDBC_PATH}/#{TEAMCITY_JAR_NAME}" do
  destination TEAMCITY_JDBC_PATH
  owner TEAMCITY_USERNAME
  group TEAMCITY_GROUP
  umask 022
  action :extract
  not_if { ::File.exists?("#{TEAMCITY_JDBC_PATH}/#{TEAMCITY_JDBC_NAME}-bin.jar") } 
end

bash 'move jdbc jar and cleanup' do
  user 'root'
  cwd '/tmp'
  code <<-EOH
    mv #{TEAMCITY_JDBC_PATH}/#{TEAMCITY_JDBC_NAME}/#{TEAMCITY_JDBC_NAME}-bin.jar #{TEAMCITY_JDBC_PATH}/#{TEAMCITY_JDBC_NAME}-bin.jar
    rm -rf #{TEAMCITY_JDBC_PATH}/#{TEAMCITY_JDBC_NAME}/
    rm -rf #{TEAMCITY_JDBC_PATH}/#{TEAMCITY_JAR_NAME}
  EOH
  not_if { ::File.exists?("#{TEAMCITY_JDBC_PATH}/#{TEAMCITY_JDBC_NAME}-bin.jar") } 
end

if TEAMCITY_BACKUP_FILE
  backup_file = ::File.basename(URI.parse(TEAMCITY_BACKUP_FILE).path)
  processed_backup_file = File.basename(backup_file, '.*')
  backup_path = ::File.join(TEAMCITY_BACKUP_PATH, backup_file)
  processed_backup_path = ::File.join(TEAMCITY_BACKUP_PATH, processed_backup_file)
  home_database_props = ::File.join(TEAMCITY_HOME_PATH, TEAMCITY_DATABASE_PROPS_NAME)

  remote_file backup_path do
    source TEAMCITY_BACKUP_FILE
    owner TEAMCITY_USERNAME
    group TEAMCITY_GROUP
    mode 0644
    not_if { ::File.exists?(processed_backup_path) }
  end

  template home_database_props do
    source 'database.properties.erb'
    mode 0644
    owner TEAMCITY_USERNAME
    group TEAMCITY_GROUP
    variables(
                url: TEAMCITY_DB_CONNECTION_URL,
                username: TEAMCITY_DB_USERNAME,
                password: TEAMCITY_DB_PASSWORD
              )
  end

  bash 'restore' do
    user TEAMCITY_USERNAME
    group TEAMCITY_GROUP
    code <<-EOH
      #{TEAMCITY_BIN_PATH}/maintainDB.sh restore -F #{backup_file} -A #{TEAMCITY_DATA_PATH} -T #{home_database_props}
      rm -f #{backup_path}
      touch #{processed_backup_path}
    EOH
    not_if { ::File.exists?(processed_backup_path) }
  end
end

template TEAMCITY_DATABASE_PROPS_PATH do
  source 'database.properties.erb'
  mode 0644
  owner TEAMCITY_USERNAME
  group TEAMCITY_GROUP
  variables(
              url: TEAMCITY_DB_CONNECTION_URL,
              username: TEAMCITY_DB_USERNAME,
              password: TEAMCITY_DB_PASSWORD
            )
  notifies :restart, "service[#{TEAMCITY_SERVICE_NAME}]", :delayed
end

template TEAMCITY_INIT_LOCATION do
  source 'teamcity_server_init.erb'
  mode 0755
  owner 'root'
  group 'root'
  variables(
              teamcity_user_name: TEAMCITY_USERNAME,
              teamcity_server_executable: TEAMCITY_SERVER_EXECUTABLE,
              teamcity_data_path: TEAMCITY_DATA_PATH,
              teamcity_pidfile: TEAMCITY_PID_FILE,
              teamcity_service_name: TEAMCITY_SERVICE_NAME
            )
  notifies :restart, "service[#{TEAMCITY_SERVICE_NAME}]", :delayed
end

service TEAMCITY_SERVICE_NAME do
  supports start: true, stop: true, restart: true, status: true
  action [:enable, :start]
end
