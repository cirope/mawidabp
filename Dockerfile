ARG QUEMU_IMAGE=multiarch/qemu-user-static:x86_64-aarch64
ARG RAILS_ENV=production

# -----------------------
# --- Assets builder ----
# -----------------------


FROM $QUEMU_IMAGE as qemu
FROM ruby:alpine as builder

ARG APP_ROOT=/opt/app

RUN apk add --update --no-cache\
 build-base     \
 curl           \
 nodejs         \
 postgresql-dev \
 tzdata         \
 libc6-compat   \
 libpq-dev      \
 ca-certificates \
 vim

RUN mkdir -p $APP_ROOT

COPY . $APP_ROOT

WORKDIR $APP_ROOT

#COPY Gemfile Gemfile.lock ./

RUN gem update --system && gem update --force --no-document

RUN bundle config set deployment 'true' && bundle install

COPY config/application.yml.kamal $APP_ROOT/config/application.yml

RUN bundle exec rails assets:precompile DB_ADAPTER=nulldb
#RUN bundle exec rake help:install
#RUN rm -rf config/jekyll/_site
#RUN bundle exec rake help:create_bootstrap_symlinks
#RUN bundle exec rake help:generate
RUN chgrp -R 0 $APP_ROOT && chmod -R g+rwX $APP_ROOT

# -----------------------
# ---- Release image ----
# -----------------------

FROM ruby:alpine

ARG APP_ROOT=/opt/app
ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_SERVE_STATIC_FILES true
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV HOME $APP_HOME
ENV PORT 3000

RUN apk add --update --no-cache\
 build-base     \
 curl           \
 nodejs         \
 postgresql-dev \
 tzdata         \
 libc6-compat   \
 ca-certificates \
 vim

COPY --from=builder $APP_ROOT $APP_ROOT
COPY --from=builder $GEM_HOME $GEM_HOME

WORKDIR $APP_ROOT

EXPOSE $PORT

CMD [ "bundle", "exec", "rails", "server" ]
