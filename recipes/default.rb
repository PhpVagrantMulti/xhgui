##
# default.rb
# Installs xhgui
# Cookbook Name:: xhgui
# Recipe:: default
# AUTHORS::   Seth Griffin <griffinseth@yahoo.com>
# Copyright:: Copyright 2015 Authors
# License::   GPLv3
#
# This file is part of PhpVagrantMulti.
# PhpVagrantMulti is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# PhpVagrantMulti is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with PhpVagrantMulti.  If not, see <http://www.gnu.org/licenses/>.
##

%w{php5-xhprof php5-mongo mongodb}.each() do |pkg|
    package pkg do
        action :install
    end
end

execute "enable_ext_xhprof" do
    command "sudo php5enmod xhprof"
    action :run
end

directory node["xhgui"]["dir"] do
    owner "www-data"
    group "www-data"
    mode  "0755"
    action :create
end

cookbook_file '/opt/xhgui-db90a070b8.zip' do
  source 'xhgui-db90a070b8.zip'
  owner 'vagrant'
  group 'vagrant'
  mode '0755'
  action :create
end

execute "unpack_xhgui" do
    not_if { Dir.exists?("/opt/xhgui-db90a070b8") }
    command "sudo unzip /opt/xhgui-db90a070b8.zip -d /opt/xhgui-db90a070b8"
    action :run
end

directory "/var/www/html/local.xhgui.com" do
    owner "www-data"
    group "www-data"
    mode  "0755"
    action :create
end

execute "install_xhgui" do
    command "sudo cp -r /opt/xhgui-db90a070b8/xhgui/* /var/www/html/local.xhgui.com/"
    action :run
end

cookbook_file "xhprof.ini" do
    action :create
    path "/etc/php5/mods-available/xhprof.ini"
end

file "/etc/php5/mods-available/xhprof_outputdir_override.ini" do
    owner 'root'
    group 'root'
    mode  '0444'
    content "xhprof.output_dir=/var/tmp/xhprof"
end

execute "enable_xhprof_outputdir_override_apache" do
    not_if { File.exists?("/etc/php5/apache2/conf.d/20-xhprof_outputdir_override.ini") }
    command "sudo ln -s /etc/php5/mods-available/xhprof_outputdir_override.ini /etc/php5/apache2/conf.d/20-xhprof_outputdir_override.ini"
    action :run
end

execute "enable_xhprof_outputdir_override_cli" do
    not_if { File.exists?("/etc/php5/cli/conf.d/20-xhprof_outputdir_override.ini") }
    command "sudo ln -s /etc/php5/mods-available/xhprof_outputdir_override.ini /etc/php5/cli/conf.d/20-xhprof_outputdir_override.ini"
    action :run
    notifies :restart, "service[apache2]", :immediately
end

execute "run_xhgui_installer" do
    command "sudo php install.php"
    cwd     "/var/www/html/local.xhgui.com"
    action :run
end

execute "run_xhgui_composer_update" do
    command "sudo php composer.phar update --prefer-dist"
    cwd     "/var/www/html/local.xhgui.com"
    action :run
end

template "local.xhgui.com.conf" do
    path "#{node["apache"]["dir"]}/sites-available/local.xhgui.com.conf"
    source "local.xhgui.com.conf.erb"
    owner  "www-data"
    group  "www-data"
    mode   "0644"
end

execute "enable_xhgui" do
    command "sudo a2ensite local.xhgui.com"
    action :run
    notifies :restart, "service[apache2]", :immediately
end
