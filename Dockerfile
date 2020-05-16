# Multi-Stage Build File for a complete FastBin deployment

# set up nginx build container
FROM alpine:latest AS nginx
RUN apk add gcc g++ git curl make linux-headers tar gzip
# download pcre library
WORKDIR /src/pcre
ARG PCRE_VER="8.44"
RUN curl -L -O "https://cfhcable.dl.sourceforge.net/project/pcre/pcre/$PCRE_VER/pcre-$PCRE_VER.tar.gz"
RUN tar xzf "/src/pcre/pcre-$PCRE_VER.tar.gz"
# download nginx source
WORKDIR /src/nginx
ARG NGINX_VER="1.18.0"
RUN curl -L -O "http://nginx.org/download/nginx-$NGINX_VER.tar.gz"
RUN tar xzf "nginx-$NGINX_VER.tar.gz"
# configure and build nginx
WORKDIR /src/nginx/nginx-"$NGINX_VER"
RUN ./configure --prefix=/usr/share/nginx \
	--sbin-path=/usr/sbin/nginx \
	--conf-path=/etc/nginx/nginx.conf \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
	--pid-path=/run/nginx.pid \
	--lock-path=/run/lock/subsys/nginx \
	--http-client-body-temp-path=/tmp/nginx/client \
	--http-proxy-temp-path=/tmp/nginx/proxy \
	--user=www-data \
	--group=www-data \
	--with-threads \
	--with-file-aio \
	--with-pcre="/src/pcre/pcre-$PCRE_VER" \
	--with-pcre-jit \
	--with-http_addition_module \
	--without-http_fastcgi_module \
	--without-http_uwsgi_module \
	--without-http_scgi_module \
	--without-http_gzip_module \
	--without-select_module \
	--without-poll_module \
	--without-mail_pop3_module \
	--without-mail_imap_module \
	--without-mail_smtp_module \
	--with-cc-opt="-Wl,--gc-sections -static -static-libgcc -O2 -ffunction-sections -fdata-sections -fPIE -fstack-protector-all -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security"
ARG CORE_COUNT="1"
RUN make -j"$CORE_COUNT"
RUN make install

# build the API server binaries
FROM mcr.microsoft.com/dotnet/core/sdk:3.1-alpine3.11 AS server
WORKDIR /src
ADD https://api.github.com/repos/galenguyer/fastbin-server/git/refs/heads/master version.json
RUN apk add git
RUN git clone https://github.com/galenguyer/fastbin-server fastbin
WORKDIR /src/fastbin/FastBin-Server
RUN dotnet restore
RUN dotnet publish -r linux-musl-x64

# fetch the latest web files
FROM alpine:latest AS web
WORKDIR /src
ADD https://api.github.com/repos/galenguyer/fastbin-web/git/refs/heads/master version.json
RUN apk add git
RUN git clone https://github.com/galenguyer/fastbin-web web

# set up the final container
FROM mcr.microsoft.com/dotnet/core/runtime-deps:3.1-alpine3.11
WORKDIR /app
RUN apk add supervisor
# setup nginx folders and files
RUN adduser www-data -D -H
RUN mkdir -p /tmp/nginx/{client,proxy} && chown -R www-data:www-data /tmp/nginx/
RUN mkdir -p /var/log/nginx && chown -R www-data:www-data /var/log/nginx
RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html
RUN touch /run/nginx.pid && chown www-data:www-data /run/nginx.pid
RUN mkdir -p /etc/nginx 
# add nginx binaries and confs
COPY --from=nginx /usr/sbin/nginx /usr/sbin/nginx
COPY image/nginx.conf /etc/nginx/nginx.conf
COPY image/mime.types /etc/nginx/mime.types
# add supervisord conf
COPY image/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
# add api server binaries
COPY --from=server /src/fastbin/FastBin-Server/bin/Debug/netcoreapp3.1/linux-musl-x64/publish .
# add web files
COPY --from=web /src/web /var/www/html
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

