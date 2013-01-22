require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
# require 'mina/foreman'
# require 'mina/rbenv'  # for rbenv support. (http://rbenv.org)
# require 'mina/rvm'    # for rvm support. (http://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :domain, '192.168.4.90'
set :application, 'lightwave'
set :deploy_to, "/home/pi/#{application}"
set :repository, 'git@github.com:scsmith/lightwaverf-sinatra.git'
set :branch, 'pi'
set :packages, %w{ dialog curl bison build-essential zlib1g-dev libssl-dev libreadline-gplv2-dev libxml2-dev libxslt-dev git-core ruby1.9.1 ruby1.9.1-dev }

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['log', 'tmp']

# Optional settings:
set :user, 'pi'    # Username in the server to SSH to.
set :forward_agent, true
#   set :port, '30000'     # SSH port number.

# Add an SSH key so we don't have to keep logging in
set :ssh_key, ENV['SSH_KEY']

# Set foreman settings
set :foreman_app, application
set :foreman_user, 'pi'
set :foreman_log,  "#{deploy_to}/#{shared_path}/log"

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use[ruby-1.9.3-p125@default]'
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  invoke :'setup:copy_public_key'
  invoke :'setup:update_packages'
  invoke :'setup:install_bundler'
end

namespace :setup do
  task :copy_public_key => :environment do
    queue %[echo "-----> Copying public key"]
    queue %[mkdir -p -m 700 /home/#{user}/.ssh]
    queue %[echo "#{ssh_key}" > .ssh/authorized_keys]
    queue %[echo "-----> Done."]
  end

  task :update_packages => :environment do
    queue %[echo "-----> Updating Packages"]
    queue %[sudo apt-get update -qy >/dev/null]
    packages.each do |name|
      queue %[echo "-----> Installing #{name}"]
      queue %[dpkg-query --show -f '${Status}' #{name} 2>/dev/null|egrep -q "^install ok installed$" || sudo apt-get install -qy #{name}]
    end
    queue %[echo "-----> Done."]
  end

  task :install_bundler => :environment do
    queue %[echo "-----> Installing Bundler"]
    queue %[sudo gem install bundler --no-ri --no-rdoc]
    queue %[echo "-----> Done."]
  end
end

namespace :foreman do
  task :export => :environment do
    queue %[sudo bundle exec foreman export initscript /etc/init.d/ -f ./Procfile -d #{deploy_to}/#{current_path} -a #{foreman_app} -u #{foreman_user} -l #{foreman_log}]
    queue %[sudo chmod +x /etc/init.d/#{foreman_app}]
  end

  task :at_boot => :environment do
    queue %[sudo update-rc.d #{foreman_app} defaults]
  end

  task :stop_boot => :environment do
    queue %[sudo update-rc.d -f #{foreman_app} remove]
  end

  task :restart do
    queue %[sudo /etc/init.d/#{foreman_app} restart || sudo /etc/init.d/#{foreman_app} start]
  end
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'foreman:export'
    invoke :'foreman:at_boot'

    to :launch do
      invoke :'foreman:restart'
    end
  end
end

