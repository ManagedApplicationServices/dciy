require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rvm'

set :domain, '10.0.0.243'
set :deploy_to, '/home/ubuntu/dciy-ci'
set :repository, 'git@github.com:ManagedApplicationServices/dciy.git'
set :branch, 'master'
set :rvm_path, '/usr/local/rvm/scripts/rvm'

set :shared_paths, ['config/database.yml', '.env']

set :user, 'ubuntu'    # Username in the server to SSH to.
set :port, '22 -A'     # SSH port number.
set :forward_agent, true     # SSH forward_agent.
#set :bash_options, '-i'

task :environment do
  invoke :'rvm:use[2.0.0-p247@ci]'
end

task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/log"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/config"]

  queue! %[touch "#{deploy_to}/#{shared_path}/config/database.yml"]
  queue  %[echo "-----> Be sure to edit '#{deploy_to}/#{shared_path}/config/database.yml'."]
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  to :before_hook do
    # Put things to run locally before ssh
  end

  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    to :launch do
      queue "cd #{deploy_to}/#{current_path}; rvm use 2.0.0-p247@ci; bundle exec sidekiq -d -l log/sidekiq.log -e production"
      queue "cd #{deploy_to}/#{current_path}; rvm use 2.0.0-p247@ci; RAILS_ENV=production nohup bundle exec rails server -p 6161 -d"
    end
  end
end
