#!/bin/bash

wget https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-1.8.5-linux-x86_64.tar.gz

tar -xvzf julia-1.8.5-linux-x86_64.tar.gz

# write the following  to ~/.profile

echo "export PATH=$PATH:/home/ngrenewables/julia-1.8.5/bin" >> ~/.profile

julia -e 'using Pkg; Pkg.add("https://github.com/JuliaPluto/PlutoSliderServer.jl"); exit()'


# cat the following to PlutoDeployment.toml 
echo "
[SliderServer]
host = "0.0.0.0"
port = 2345

[Export]
slider_server_url = "https://yourwebsitegoeshere.com"
" >> ~/.julia/config/PlutoDeployment.toml

echo "
import PlutoSliderServer
PlutoSliderServer.run_directory("."; static_export=true, config_toml_path="./PlutoDeployment.toml")
" >> ~/.julia/config/start.jl

sudo apt install nginx

sudo echo "
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    location / {
        proxy_pass http://127.0.0.1:2345/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
    }
}
" >> /etc/nginx/sites-available/default

sudo systemctl restart nginx