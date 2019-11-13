FROM ruby:2.6-alpine

ENV APP_HOME /opt/app
ENV BUNDLE_BIN $GEM_HOME/bin
ENV BUNDLE_GEMFILE $APP_HOME/Gemfile
ENV PATH $BUNDLE_BIN:$PATH
ENV RAILS_ENV production

ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_SERVE_STATIC_FILES true

ENV HOME $APP_HOME
ENV USER nobody
ENV PORT 3000

RUN apk add --update --no-cache \
  build-base                    \
  imagemagick                   \
  linux-headers                 \
  nodejs                        \
  postgresql-dev                \
  tzdata

RUN mkdir $APP_HOME

ADD Gemfile $APP_HOME/Gemfile
ADD Gemfile.lock $APP_HOME/Gemfile.lock

RUN gem update --system && gem update --force --no-document
RUN bundle install --deployment

ADD . $APP_HOME
ADD config/application.yml.example $APP_HOME/config/application.yml

WORKDIR $APP_HOME

RUN bundle exec rails assets:precompile DB_ADAPTER=nulldb

RUN chgrp -R 0 $APP_HOME && chmod -R g+rwX $APP_HOME

USER $USER

EXPOSE $PORT

CMD [ "bundle", "exec", "rails", "server" ]
