#Dockerfile
FROM ruby:2.3.7
LABEL maintainer="Scott Bishop - ScottBishop70@gmail.com"

# Install tools & libs
RUN apt-get update
RUN apt-get install -y build-essential checkinstall libx11-dev libxext-dev zlib1g-dev libpng-dev libjpeg-dev libfreetype6-dev libxml2-dev nodejs

RUN apt-get install -y imagemagick libmagick++-dev libmagic-dev libmagickwand-dev vim libpq-dev && apt-get clean

WORKDIR /app
COPY Gemfile* ./
RUN gem install bundler
RUN bundle install

COPY . /app

# add encription key to decode secrets
ARG RAILS_MASTER_KEY

# precompile rails assets and remove file limits for ImageMagick for builds that calculate lots of diffs
RUN rake assets:precompile && rm -f /etc/ImageMagick-6/policy.xml

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
