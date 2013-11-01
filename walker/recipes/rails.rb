#
# Cookbook Name:: walker
# Recipe:: default
#
# Copyright 2013, W&Co
#
# All rights reserved - Do Not Redistribute
#

Chef::Log.info "All your nodes belong to us..."
Chef::Log.info "node: #{node[:opsworks].inspect}"
Chef::Log.info "node: #{node[:unicorn].inspect}"

locals = {}
locals[:unicorn_workers] = node[:unicorn][:worker_processes]

node[:deploy].each do |application, deploy|
  Chef::Log.info "Setting up Walker Custom Stuff"
  Chef::Log.info "deploy: #{deploy.inspect}"
  Chef::Log.info "deploy: #{application.inspect}"

  locals[:deploy_to] = "/srv/www/#{application}"
  locals[:current_path] = "#{locals[:deploy_to]}/current"
  locals[:shared_path] = "#{locals[:deploy_to]}/shared"
  locals[:rails_env] = deploy[:rails_env]
  #  setup  nginx, unicorn, sidekiq monit templates

  template File.join(node[:monit][:conf_dir],'nginx.monitrc') do
    source "nginx.monitrc.erb"
    cookbook 'walker'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    #variables(:settings => deploy[:settings], :environment => deploy[:rails_env])

    only_if do
      File.exists?("#{node[:monit][:conf_dir]}")
    end
  end

  template File.join(node[:monit][:conf_dir],'unicorn.monitrc') do
    source "unicorn.monitrc.erb"
    cookbook 'walker'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]

    variables(:locals => locals, :application => application)

    only_if do
      File.exists?("#{node[:monit][:conf_dir]}")
    end
  end

  template File.join("/etc/init.d/",'unicorn') do
    source "unicorn.erb"
    cookbook 'walker'
    mode "0771"
    group deploy[:group]
    owner deploy[:user]

    variables(:locals => locals, :application => application)

    only_if do
      File.exists?("/etc/init.d/")
    end
  end

  #http://chrisdyer.info/2013/04/06/init-script-for-sidekiq-with-rbenv.html
  template File.join("/etc/init.d/",'sidekiq') do
    source "sidekiq.erb"
    cookbook 'walker'
    mode "0771"
    group deploy[:group]
    owner deploy[:user]

    variables(:locals => locals, :application => application)

    only_if do
      File.exists?("/etc/init.d/")
    end
  end

  template File.join(node[:monit][:conf_dir],'sidekiq.monitrc') do
    source "sidekiq.monitrc.erb"
    cookbook 'walker'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]

    variables(:locals => locals, :application => application)

    only_if do
      File.exists?("#{node[:monit][:conf_dir]}")
    end
  end

  execute "reload monit" do
    command "/etc/init.d/monit restart"
  end

end
