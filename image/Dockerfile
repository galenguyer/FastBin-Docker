# use latest alpine as base
FROM mcr.microsoft.com/dotnet/core/runtime-deps:3.1-alpine3.11

# determine nginx version to use
ARG version

# install supervisord
RUN apk --no-cache add supervisor 

# copy nginx binary
COPY nginx /usr/sbin/nginx

# configure supervisord configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# add nginx user
RUN adduser www-data -D -H

# create necessary directories and files
RUN mkdir -p /tmp/nginx/{client,proxy} && chown -R www-data:www-data /tmp/nginx/
RUN mkdir -p /var/log/nginx && chown -R www-data:www-data /var/log/nginx
RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html
RUN touch /run/nginx.pid && chown www-data:www-data /run/nginx.pid
RUN mkdir -p /etc/nginx
RUN mkdir /app

# copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# copy web files
COPY web /var/www/html
COPY server /app

# expose nginx port
EXPOSE 80

# set this or we get permission errors with dotnet
WORKDIR /app
# run nginx and fastbin-server in supervisord
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
