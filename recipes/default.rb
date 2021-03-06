#
# Cookbook Name:: chef-teamcity
# Recipe:: default
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

TEAMCITY_USERNAME = node['teamcity']['username']
TEAMCITY_PASSWORD = node['teamcity']['password']
TEAMCITY_GROUP = node['teamcity']['group']
TEAMCITY_HOME_PATH = "/home/#{TEAMCITY_USERNAME}"

include_recipe 'java::oracle'
include_recipe 'git'

if node['platform'] != 'windows'
  package 'git'

  group TEAMCITY_GROUP

  user TEAMCITY_USERNAME do
    supports manage_home: true
    home TEAMCITY_HOME_PATH
    gid TEAMCITY_GROUP
    shell '/bin/bash'
    password TEAMCITY_PASSWORD
  end
end
