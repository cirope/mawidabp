# -----------------------
# --- Assets builder ----
# -----------------------

FROM --platform=$BUILDPLATFORM ruby:alpine as builder

ARG APP_ROOT=/opt/app
ENV RAILS_ENV production

RUN apk add --update --no-cache\
 build-base     \
 curl           \
 nodejs         \
 postgresql-dev \
 tzdata         \
 libc6-compat   \
 libpq-dev      \
 ca-certificates

RUN mkdir -p $APP_ROOT

COPY . $APP_ROOT

WORKDIR $APP_ROOT

RUN gem update --system && gem update --force --no-document

RUN bundle config set deployment 'true' && bundle install

COPY config/application.yml.kamal $APP_ROOT/config/application.yml

RUN bundle exec rails assets:precompile DB_ADAPTER=nulldb

# -----------------------
# ---- Release image ----
# -----------------------

FROM --platform=$BUILDPLATFORM ruby:alpine

ARG APP_ROOT=/opt/app
ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_SERVE_STATIC_FILES true
ENV USER nobody
ENV PORT 3000
ENV RAILS_ENV production

RUN apk add --update --no-cache\
 curl           \
 nodejs         \
 postgresql-dev \
 tzdata         \
 libc6-compat   \
 ca-certificates \
 libpq-dev

COPY --from=builder $APP_ROOT $APP_ROOT
COPY --from=builder $GEM_HOME $GEM_HOME

RUN chown -R $USER: $APP_ROOT

WORKDIR $APP_ROOT

USER $USER

EXPOSE $PORT

CMD [ "bundle", "exec", "rails", "server" ]
