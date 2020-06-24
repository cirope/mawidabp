FROM centos/ruby-25-centos7

ENV APP_ROOT /opt/app

ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_ENV production

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

ENV USER_ID 1001
ENV PORT 3000

ENV PATH /opt/rh/rh-ruby${RUBY_MAJOR_VERSION}${RUBY_MINOR_VERSION}/root/bin/:$PATH
ENV LD_LIBRARY_PATH /opt/rh/rh-ruby${RUBY_MAJOR_VERSION}${RUBY_MINOR_VERSION}/root/usr/lib64

USER root

RUN sed 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/fastestmirror.conf > /etc/yum/pluginconf.d/fastestmirror.conf

RUN curl -sL https://rpm.nodesource.com/setup_10.x | bash -

RUN yum update -y && \
  yum install -y     \
  autoconf           \
  automake           \
  bison              \
  bzip2              \
  flex               \
  gcc                \
  gcc-c++            \
  gettext            \
  git-core           \
  iconv-devel        \
  ImageMagick        \
  kernel-devel       \
  libffi-devel       \
  libtool            \
  libyaml-devel      \
  m4                 \
  make               \
  ncurses-devel      \
  nodejs             \
  openssl-devel      \
  patch              \
  postgresql-devel   \
  readline           \
  readline-devel     \
  tzdata             \
  zlib               \
  zlib-devel      && \
  yum clean all -y

RUN mkdir -p $APP_ROOT

COPY Gemfile $APP_ROOT/Gemfile
COPY Gemfile.lock $APP_ROOT/Gemfile.lock

WORKDIR $APP_ROOT

RUN gem install bundler --no-document --force        && \
    bundle config set deployment 'true'              && \
    bundle config --global silence_root_warning true && \
    bundle install

COPY . $APP_ROOT
COPY config/application.bh.yml $APP_ROOT/config/application.yml

RUN bundle exec rails assets:precompile DB_ADAPTER=nulldb
RUN bundle config set deployment 'false' && \
    bundle exec rake help:install        && \
    bundle exec rake help:generate

RUN chgrp -R 0 $APP_ROOT && chmod -R g+rwX $APP_ROOT
RUN chmod +x scripts/migrate.sh scripts/wait.sh

USER $USER_ID

EXPOSE $PORT

ENTRYPOINT [ "/usr/bin/env" ]
CMD [ "bundle", "exec", "rails", "server" ]
