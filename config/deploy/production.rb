set :rails_env, :production

server 'webdns4.grnet.gr', user: 'webdns', roles: %w(web app db)

set :ssh_options, forward_agent: false
