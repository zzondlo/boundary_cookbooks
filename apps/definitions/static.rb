#
# Author:: Joe Williams (<j@boundary.com>)
# Cookbook Name:: apps
# Definition:: static
#
# Copyright 2011, Boundary
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

#
# installl standard dependencies
#

define :install_standard_static_dependencies, :name => nil, :deploy_config => nil do

  if params[:deploy_config]
    deploy_config = params[:deploy_config]
  else
    deploy_config =  data_bag_item("apps", params[:name])
  end

  include_recipe "git"

  if deploy_config["config"]["webserver"] == "nginx"
    include_recipe "nginx"
  elsif deploy_config["config"]["webserver"] == "apache"
    include_recipe "apache2"
  end

end

#
# git deploy specifically for static apps
#

define :git_deploy_static, :name => nil, :deploy_config => nil do

  if params[:deploy_config]
    deploy_config = params[:deploy_config]
  else
    deploy_config =  data_bag_item("apps", params[:name])
  end

  git "#{deploy_config["install"]["path"]}/#{deploy_config["id"]}" do
    repository  deploy_config["config"]["git"]["repository"]
    reference   deploy_config["config"]["git"]["reference"]
    action      :sync
    ssh_wrapper "#{deploy_config["install"]["path"]}/etc/git_ssh.sh"
  end

end


#
# web server config
#

define :web_server_config, :name => nil, :deploy_config => nil, :app_options => nil do

  if params[:deploy_config]
    deploy_config = params[:deploy_config]
  else
    deploy_config =  data_bag_item("apps", params[:name])
  end

  if deploy_config["config"]["webserver"] == "nginx"

    #
    # nginx config
    #

    template "#{node[:nginx][:dir]}/sites-available/#{deploy_config["id"]}.conf" do
      source "static/#{deploy_config["id"]}.conf.erb"
      owner "root"
      group "root"
      mode 0644
      variables :deploy_config => deploy_config, :app_options => params[:app_options]
      notifies :reload, resources(:service => "nginx")
    end

    nginx_site "#{deploy_config["id"]}.conf"

  elsif deploy_config["config"]["webserver"] == "apache"

    #
    # apache config
    #

    template "#{node[:apache][:dir]}/sites-available/#{deploy_config["id"]}.conf" do
      source "static/#{deploy_config["id"]}.conf.erb"
      owner "root"
      group "root"
      mode 0644
      variables :deploy_config => deploy_config, :app_options => params[:app_options]
      notifies :reload, resources(:service => "apache2")
    end

    apache_site "#{deploy_config["id"]}.conf"

  end

end