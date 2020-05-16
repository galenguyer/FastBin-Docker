# use latest alpine as base
FROM alpine:latest

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

# create client body temp path
RUN mkdir -p /tmp/nginx/{client,proxy} && chown -R www-data:www-data /tmp/nginx/

# create pid file
RUN touch /run/nginx.pid && chown www-data:www-data /run/nginx.pid

# expose nginx port
EXPOSE 80

# run nginx in supervisord
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]