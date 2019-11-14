FROM centos:2.6-alpine

ENV APP_HOME /opt/app

ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_ENV production

ENV HOME $APP_HOME
ENV USER_ID 1001
ENV PORT 3000

RUN curl -sL https://rpm.nodesource.com/setup_10.x | bash -

RUN yum update -y && \
  yum install -y     \
  ImageMagick        \
  nodejs             \
  openssl-devel      \
  postgresql-devel   \
  tzdata          && \
  yum clean all -y


RUN mkdir -p $APP_HOME

WORKDIR $APP_HOME

ADD Gemfile $APP_HOME/Gemfile
ADD Gemfile.lock $APP_HOME/Gemfile.lock

RUN bundle install --deployment

ADD . $APP_HOME
ADD config/application.yml.example $APP_HOME/config/application.yml

RUN bundle exec rails assets:precompile DB_ADAPTER=nulldb

RUN chgrp -R 0 $APP_HOME && chmod -R g+rwX $APP_HOME

USER $USER_ID

EXPOSE $PORT

CMD [ "bundle", "exec", "rails", "server" ]
