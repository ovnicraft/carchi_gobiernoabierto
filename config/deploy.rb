# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'openirekia'
set :repo_url, 'https://github.com/alabs/carchi_gobiernoabierto.git'
set :scm, :git
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/data', 'public/uploads')

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end
  after :publishing, :restart

  ## http://stackoverflow.com/a/1645590
  #namespace :deploy do
  #  task :cold do       # Overriding the default deploy:cold
  #    update
  #    load_schema       # My own step, replacing migrations.
  #    start
  #  end
  #  task :load_schema, :roles => :app do
  #    run "cd #{current_path}; rake db:schema:load"
  #  end
  #end
  #
end

namespace :deploy do

  task :cold do
    invoke 'deploy:starting'
    invoke 'deploy:started'
    invoke 'deploy:updating'
    invoke 'bundler:install'
    invoke 'deploy:load_schema' # This replaces deploy:migrations
    invoke 'deploy:compile_assets'
    invoke 'deploy:normalize_assets'
    invoke 'deploy:publishing'
    invoke 'deploy:published'
    invoke 'deploy:finishing'
    invoke 'deploy:finished'
  end

  desc 'Load DB schema - CAUTION: rewrites database!'
  task :load_schema do
    on roles(:db) do 
      within release_path do
        with rails_env: (fetch(:rails_env) || fetch(:stage)) do
          execute :rake, 'db:schema:load' # This creates the database tables AND seeds
        end
      end
    end
  end

end
