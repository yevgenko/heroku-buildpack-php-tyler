# setting worker_processes to CPU core count
worker_processes      1;
daemon off;

events {
  worker_connections  1024;
}

http {
  include             mime.types;
  default_type        application/octet-stream;
  sendfile            on;
  keepalive_timeout   65;
  gzip                on;
  access_log          off;
  proxy_max_temp_file_size	0;
  #fastcgi_max_temp_file_size	0;
  limit_conn_zone $binary_remote_addr zone=phplimit:1m; # define a limit bucket for PHP-FPM

  server {
    listen            $PORT;
    server_name       _;

    root              /app/;
    index             index.php index.html index.htm;

    # Some basic cache-control for static files to be sent to the browser
    location ~* \.(?:ico|css|js|gif|jpeg|jpg|png)$ {
      expires         max;
      add_header      Pragma public;
      add_header      Cache-Control "public, must-revalidate, proxy-revalidate";
    }

    # Deny hidden files (.htaccess, .htpasswd, .DS_Store).
    location ~ /\. {
      deny            all;
      access_log      off;
      log_not_found   off;
    }

    # Deny /favicon.ico
    location = /favicon.ico {
      access_log      off;
      log_not_found   off;
    }

    # Deny /robots.txt
    location = /robots.txt {
      allow           all;
      log_not_found   off;
      access_log      off;
    }

    # Status. /status.html uses /status
    location ~ ^/(status|ping)$ {
      include         /app/vendor/nginx/conf/fastcgi_params;
      fastcgi_param   HTTPS on; # force SSL
      fastcgi_pass    unix:/tmp/php-fpm.socket;
      fastcgi_param   SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    location /server-status {
      stub_status on;
      access_log   off;
    }

    #location / {
    #  # wordpress fancy rewrites
    #  if (-f $request_filename) {
    #    break;
    #  }
    #  if (-d $request_filename) {
    #    break;
    #  }

    #  rewrite         ^(.+)$ /index.php?q=$1 last;

    #  # Add trailing slash to */wp-admin requests.
    #  rewrite         /wp-admin$ $scheme://$host$uri/ permanent;

    #  # redirect to feedburner.
    #  # if ($http_user_agent !~ FeedBurner) {
    #  #   rewrite ^/feed/?$ http://feeds.feedburner.com/feedburner-feed-id last;
    #  # }
    #}

    location ~ .*\.php$ {
      try_files $uri =404;
      limit_conn phplimit 5; # limit to 5 concurrent users to PHP per IP.
      include         /app/vendor/nginx/conf/fastcgi_params;
      fastcgi_param   HTTPS on; # force SSL
      fastcgi_pass    unix:/tmp/php-fpm.socket;
      fastcgi_param   SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
  }
}
