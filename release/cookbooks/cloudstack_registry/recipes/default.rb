include_recipe "env"
include_recipe "ruby"
include_recipe "rubygems"
include_recipe "runit"

runit_service "cloudstack_registry" do
  run_restart false
end

package "git-core"

directory "#{node[:cloudstack_registry][:path]}/shared" do
  owner node[:cloudstack_registry][:runner]
  group node[:cloudstack_registry][:runner]
  mode "0755"
  recursive true
  action :create
end

directory node[:cloudstack_registry][:tmp] do
  mode "1777"
  recursive true
  action :create
end

%w{config gems logs}.each do |dir|
  directory "#{node[:cloudstack_registry][:path]}/shared/#{dir}" do
    owner node[:cloudstack_registry][:runner]
    group node[:cloudstack_registry][:runner]
    mode "0755"
    action :create
  end
end

template "#{node[:cloudstack_registry][:path]}/shared/config/cloudstack_registry.yml" do
  source "cloudstack_registry.yml.erb"
  owner node[:cloudstack_registry][:runner]
  group node[:cloudstack_registry][:runner]
  notifies :restart, "service[cloudstack_registry]"
end

deploy_revision node[:cloudstack_registry][:path] do
  scm_provider Chef::Provider::Git

  repo "#{node[:cloudstack_registry][:repos_path]}/bosh"
  user node[:cloudstack_registry][:runner]
  revision "HEAD"

  migrate true

  migration_command "cd cloudstack_registry && PATH=#{node[:ruby][:path]}/bin:$PATH " \
                    "./bin/migrate -c #{node[:cloudstack_registry][:path]}/shared/config/cloudstack_registry.yml"

  symlink_before_migrate({})
  symlinks({})

  shallow_clone true
  action :deploy

  restart_command do
    execute "/usr/bin/sv restart cloudstack_registry" do
      ignore_failure true
    end
  end

  before_migrate do
    execute "#{node[:ruby][:path]}/bin/bundle install " \
            "--deployment --without development test " \
            "--local --path #{node[:cloudstack_registry][:path]}/shared/gems" do
      ignore_failure true
      cwd "#{release_path}/cloudstack_registry"
    end
  end
end
