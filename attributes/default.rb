#
# Cookbook Name:: chef-teamcity
# Attributes:: teamcity
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

default['teamcity']['version'] = '9.1.3'
default['teamcity']['username'] = 'teamcity'
default['teamcity']['group'] = 'teamcity'
default['teamcity']['service_name'] = 'teamcity'


default['teamcity']['agent']['name'] = node['hostname']
default['teamcity']['agent']['server_uri'] = nil
default['teamcity']['agent']['own_address'] = nil
default['teamcity']['agent']['port'] = 9090
default['teamcity']['agent']['authorization_token'] = nil
default['teamcity']['agent']['system_properties'] = {}
default['teamcity']['agent']['env_properties'] = {}

case node['platform']
when 'windows'
  default['teamcity']['agent']['work_dir'] = 'C:/teamcity/work'
  default['teamcity']['agent']['temp_dir'] = 'C:/teamcity/tmp'
  default['teamcity']['agent']['system_dir'] = 'C:/teamcity'
else
  default['teamcity']['agent']['work_dir'] = '../work'
  default['teamcity']['agent']['temp_dir'] = '../temp'
  default['teamcity']['agent']['system_dir'] = '../system'
end

default['teamcity']['server']['database']['name'] = 'teamcity'
default['teamcity']['server']['database']['username'] = 'root'
default['teamcity']['server']['database']['password'] = 'Password1'
default['teamcity']['server']['database']['connection_url'] = "jdbc\:mysql\:///#{node['teamcity']['server']['database']['name']}"
default['teamcity']['server']['database']['jdbc_url'] = 'http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.36.tar.gz'
default['teamcity']['server']['backup'] = $false

default['java']['jdk_version'] = '8'
default['java']['oracle']['accept_oracle_download_terms'] = true

