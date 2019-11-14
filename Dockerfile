FROM centos/ruby-25-centos7

ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_ENV production

ENV USER_ID 1001
ENV PORT 3000

USER root

RUN yum update -y && \
  yum install -y     \
  ImageMagick        \
  openssl-devel      \
  postgresql-devel   \
  tzdata          && \
  yum clean all -y

ADD Gemfile $APP_ROOT/Gemfile
ADD Gemfile.lock $APP_ROOT/Gemfile.lock

RUN bash -cl "gem install bundler --no-document --force && bundle install --deployment"

ADD . $APP_ROOT
ADD config/application.yml.example $APP_ROOT/config/application.yml

RUN bash -cl "bundle exec rails assets:precompile DB_ADAPTER=nulldb"

RUN chgrp -R 0 $APP_ROOT && chmod -R g+rwX $APP_ROOT

USER $USER_ID

EXPOSE $PORT

CMD [ "bundle", "exec", "rails", "server" ]
