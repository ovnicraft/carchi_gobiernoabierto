server 'beta.gobiernoabierto.carchi.gob.ec', user: 'irekia', roles: %w{web app db}
set :ssh_options, user: 'capistrano', forward_agent: true
set :branch, "staging"
set :deploy_to, "/var/www/beta.gobiernoabierto.carchi.gob.ec"
