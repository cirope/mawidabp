FROM multiarch/qemu-user-static:x86_64-aarch64 as qemu
FROM ruby:alpine as builder

ENV APP_ROOT /opt/app

ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_ENV production

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

ENV USER_ID 1001
ENV PORT 3000

USER root

RUN apk add --update --no-cache\
 build-base                    \
 curl                         \
 nodejs                        \
 postgresql-dev                \
 tzdata \
 libc6-compat

RUN mkdir -p $APP_ROOT
WORKDIR $APP_ROOT

COPY Gemfile Gemfile.lock ./

RUN gem update --system
RUN bundle install

COPY . $APP_ROOT
COPY config/application.yml.example $APP_ROOT/config/application.yml

RUN bundle exec rails assets:precompile DB_ADAPTER=nulldb
#RUN bundle exec rake help:install
#RUN rm -rf config/jekyll/_site
#RUN bundle exec rake help:generate
#RUN bundle exec rake help:generate

RUN chgrp -R 0 $APP_ROOT && chmod -R g+rwX $APP_ROOT

USER $USER_ID

EXPOSE 3000

ENTRYPOINT [ "/usr/bin/env" ] ]
#ENTRYPOINT [ "/rails/bin/docker-entrypoint" ]
CMD [ "bundle", "exec", "rails", "server" ]
