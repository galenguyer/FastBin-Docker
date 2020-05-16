# Multi-Stage Build File for a complete FastBin deployment

# Build the server binaries
FROM mcr.microsoft.com/dotnet/core/sdk:3.1-alpine3.11 AS server
WORKDIR /src
RUN apk add git
RUN git clone https://github.com/galenguyer/fastbin-server fastbin
WORKDIR /src/fastbin/FastBin-Server
RUN dotnet restore
RUN dotnet publish -r linux-musl-x64

FROM alpine:latest AS nginx
ARG NGINX_VER="1.18.0"
ARG PCRE_VER="8.44"
ARG CORE_COUNT="1"

RUN apk add gcc g++ git curl make linux-headers tar gzip
WORKDIR /src/pcre
RUN curl -L -O "https://cfhcable.dl.sourceforge.net/project/pcre/pcre/$PCRE_VER/pcre-$PCRE_VER.tar.gz"
RUN tar xzf "/src/pcre/pcre-$PCRE_VER.tar.gz"

WORKDIR /src/nginx
RUN curl -L -O "http://nginx.org/download/nginx-$NGINX_VER.tar.gz"
RUN tar xzf "nginx-$NGINX_VER.tar.gz"

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
RUN echo "$CORE_COUNT"
RUN make -j"$CORE_COUNT"
RUN make install

FROM alpine:latest AS web
WORKDIR /src
RUN apk add git
RUN git clone https://github.com/galenguyer/fastbin-web web

FROM mcr.microsoft.com/dotnet/core/runtime-deps:3.1-alpine3.11
WORKDIR /app
RUN apk add supervisor
RUN adduser www-data -D -H
RUN mkdir -p /tmp/nginx/{client,proxy} && chown -R www-data:www-data /tmp/nginx/
RUN mkdir -p /var/log/nginx && chown -R www-data:www-data /var/log/nginx
RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html
RUN touch /run/nginx.pid && chown www-data:www-data /run/nginx.pid
RUN mkdir -p /etc/nginx 
COPY --from=nginx /usr/sbin/nginx /usr/sbin/nginx
COPY image/nginx.conf /etc/nginx/nginx.conf
COPY image/mime.types /etc/nginx/mime.types
COPY image/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY --from=server /src/fastbin/FastBin-Server/bin/Debug/netcoreapp3.1/linux-musl-x64/publish .
COPY --from=web /src/web /var/www/html
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

