require 'rubygems'
require 'capcake'
set :webroot_index_template, "index.php.erb"
set :deploy_via, :copy
set :copy_exclude, [".git/*"]

set :scm, "git"
set :application, "application name"
set :repository, "your git repositiory"
set :deploy_to, "path to deploy files to"
ssh_options[:forward_agent] = true
default_run_options[:pty] = true
 
set :scm_verbose, true

set :user, "username"
set :runner, user
role :web, "yourdomain.com"
role :app, "yourdomain.com"
role :db, "yourdomain.com", :primary => true
# Need to change the default capcake repo as current one is not used anymore
set :cake_repo, "git://github.com/cakephp/cakephp.git"
# Set version of cakePHP to check out
set :cake_branch, "1.3.1"
set :branch, "tag"

# Add any shared folders to this 
set :app_symlinks, ["webroot/folder1", "webroot/folder2"]

namespace :rehabstudio do
	namespace :symlinks do
		desc "Setup application symlinks in the webroot"
		task :setup, :roles => [:web] do
			if app_symlinks
				app_symlinks.each { |link| run "mkdir -p #{shared_path}/#{link}" }
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
		#send(run_method, "rm -f #{current_path}/webroot/index.php")
		# Should probably find a better location for this template file
		file = File.join(File.dirname(__FILE__ ), "/../../libs/templates", webroot_index_template)
		template = File.read(file)
		buffer = ERB.new(template).result(binding)
		put buffer, "#{shared_path}/webroot/index.php", :mode => 0644
		send(run_method, "ln -nfs #{shared_path}/webroot/index.php #{current_path}/webroot/index.php")
	end	
end

before  'deploy:update_code', 'rehabstudio:symlinks:setup'
after   'deploy:symlink', 'rehabstudio:symlinks:update'
capcake