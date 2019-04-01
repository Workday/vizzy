#Dockerfile
FROM ruby:2.3.7 AS base
LABEL maintainer="Scott Bishop - ScottBishop70@gmail.com"

ARG RAILS_MASTER_KEY=""
ENV BUILD_PACKAGES="build-essential checkinstall libx11-dev libmagic-dev libpq-dev libmagick++-dev"

WORKDIR /app
# Install base tools
RUN apt-get update && \
    apt-get install -y nodejs imagemagick vim ${BUILD_PACKAGES} && \
    apt-get clean && \
    gem install bundler && \
    rm -f /etc/ImageMagick-6/policy.xml && \
    chown 10001:10001 /app

COPY --chown=10001:10001 Gemfile* ./

RUN bundle install && \
    rm -rf /tmp/* /var/tmp/* /root/.bundle/cache/* /usr/local/bundle/cache/*.gem

USER 10001
COPY --chown=10001:10001  . ./
# Precompile rails assets
RUN rake assets:precompile

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
