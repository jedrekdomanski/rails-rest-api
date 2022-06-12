FROM ruby:2.7.4-alpine as base

RUN echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

RUN apk update && apk upgrade && apk add build-base && apk --no-cache add \
  tzdata \
  bash \
  git \
  libstdc++ \
  ca-certificates \
  libffi-dev \
  postgresql-dev \
  postgresql-client \
  linux-headers \
  libpq \
  openssh \
  file \
  libxml2-dev \
  curl \
  ncurses \
  gmp-dev \
  musl \
  gcompat \
  aws-cli@edge \
  shared-mime-info \
  libucontext-dev \
  && echo ‘gem: --no-document’ > /etc/gemrc

RUN mkdir -p /app/vendor/gems
WORKDIR /app

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

RUN gem install bundler:2.2.24

RUN bundle install \
  --without development test \
  --deployment

COPY . /app

RUN RAILS_ENV=staging \
    DATABASE_URL=postgres:null \
    SECRET_KEY_BASE=blah

COPY *.env *.yaml /config/

ENTRYPOINT ["bundle", "exec"]
CMD ["rails", "server", "-b", "0.0.0.0"]

# Deploy Image
FROM base as deploy
RUN rm -rf /root/.ssh

# Dev Image
FROM base as dev

RUN bundle config --delete without
RUN bundle config --delete with
RUN bundle install --with development

RUN apk update && apk upgrade && apk --no-cache add \
  curl-dev \
  postgresql \
  && echo ‘gem: --no-document’ > /etc/gemrc

RUN rm -rf /root/.ssh

# CI Image
FROM base as ci
RUN apk update && apk upgrade && apk --no-cache add \
  curl-dev \
  postgresql \
  && echo ‘gem: --no-document’ > /etc/gemrc

RUN bundle config --delete without
RUN bundle config --delete with
RUN bundle install \
  --with test \
  --deployment

RUN rm -rf /root/.ssh

COPY config/database.ci.yml config/database.yml
