require 'rubygems'
require 'capcake'
set :deploy_via, :copy
set :copy_exclude, [".git/*"]
set :scm, "git"
set :application, "my_website"
set :repository, "git@your-git-repo:#{application}.git"
set :deploy_to, "/var/www/#{application}/httpdocs"
ssh_options[:forward_agent] = true
default_run_options[:pty] = true
set :scm_verbose, true
set :user, "username"
set :runner, user
role :web, "website.com"
role :app, "website.com"
role :db, "website.com", :primary => true
set :cake_repo, "http://github.com/cakephp/cakephp.git"
set :cake_branch, "1.3.3"
set :branch, "tag"
set :debug_kit_repo, 'http://github.com/cakephp/debug_kit.git'
set :webroot_index_template, "index.php.erb"
set :app_symlinks, ["webroot/img", "webroot/files"]

# Tasks to run after deploy:setup
after "deploy:setup", 'debug_kit:setup'
after  'deploy:setup', 'rehabstudio:symlinks:setup'

# Extra symlinks to create after deployment
after   'deploy:symlink', 'rehabstudio:symlinks:update'
after   'deploy:symlink', 'debug_kit:symlink'

namespace :debug_kit do
	task :setup do
		run "cd #{shared_path} && git clone --depth 1 #{debug_kit_repo} debug_kit"
	end
	
	task :symlink do
		run "mkdir -p #{shared_path}/debug_kit"
		run "ln -s #{shared_path}/debug_kit #{latest_release}/plugins/debug_kit"
	end
end

namespace :rehabstudio do
	namespace :symlinks do
		desc "Setup application symlinks in the webroot"
		task :setup, :roles => [:web] do
			if app_symlinks
				app_symlinks.each { |link| run "mkdir -p #{shared_path}/#{link}" }
				send(run_method, "chown #{user}:psacln -R #{shared_path}/webroot")
				#send(run_method, "chown #{user}:psaserv  #{shared_path}/webroot")
				send(run_method, "chmod 777 -R #{shared_path}/webroot")
			end
		end

		desc "Link public directories to shared location."
		task :update, :roles => [:web] do
			if app_symlinks
				app_symlinks.each { |link| run "ln -nfs #{shared_path}/#{link} #{current_path}/#{link}" }
			end
			rehabstudio.webroot_index
		end
	end
	
	desc "Overwrite webroot/index.php from template"
	task :webroot_index, :roles => [:web] do
		file = File.join(File.dirname(__FILE__ ), "/../../libs/templates", webroot_index_template)
		template = File.read(file)
		buffer = ERB.new(template).result(binding)
		put buffer, "#{shared_path}/webroot/index.php", :mode => 0644
		send(run_method, "ln -nfs #{shared_path}/webroot/index.php #{current_path}/webroot/index.php")
	end	
end

capcake