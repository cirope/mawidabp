FROM centos:2.6-alpine

ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_ENV production

ENV USER_ID 1001
ENV PORT 3000

USER root

RUN curl -sL https://rpm.nodesource.com/setup_10.x | bash -

RUN yum update -y && \
  yum install -y     \
  ImageMagick        \
  nodejs             \
  openssl-devel      \
  postgresql-devel   \
  rubygems           \
  tzdata          && \
  yum clean all -y

USER $USER_ID

ADD Gemfile $APP_ROOT/Gemfile
ADD Gemfile.lock $APP_ROOT/Gemfile.lock

RUN bundle install --deployment

ADD . $APP_ROOT
ADD config/application.yml.example $APP_ROOT/config/application.yml

RUN bundle exec rails assets:precompile DB_ADAPTER=nulldb

RUN chgrp -R 0 $APP_ROOT && chmod -R g+rwX $APP_ROOT

EXPOSE $PORT

CMD [ "bundle", "exec", "rails", "server" ]
