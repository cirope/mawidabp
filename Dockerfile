# -----------------------
# --- Assets builder ----
# -----------------------

FROM --platform=$BUILDPLATFORM ruby:slim as builder

ARG APP_ROOT=/opt/app
ENV RAILS_ENV production

RUN apt-get update && \
apt-get install -y --no-install-recommends \
 build-essential     \
 nodejs         \
 postgresql-client \
 tzdata         \
 libpq-dev

RUN mkdir -p $APP_ROOT

COPY . $APP_ROOT

WORKDIR $APP_ROOT

RUN gem update --system && gem update --force --no-document

RUN bundle config set deployment 'true' && bundle install

COPY config/application.yml.example $APP_ROOT/config/application.yml

RUN bundle exec rails assets:precompile DB_ADAPTER=nulldb

RUN bundle exec whenever > $APP_ROOT/config/mawidabp_crontab

# -----------------------
# ---- Release image ----
# -----------------------

FROM --platform=$BUILDPLATFORM ruby:slim

ARG APP_ROOT=/opt/app
ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_SERVE_STATIC_FILES true
ENV USER root
ENV PORT 3000
ENV RAILS_ENV production

RUN apt-get update && \
apt-get install -y --no-install-recommends \
 build-essential     \
 curl           \
 nodejs         \
 postgresql-client \
 tzdata         \
 ca-certificates \
 bash \
 cron \
 libpq-dev

COPY --from=builder $APP_ROOT $APP_ROOT
COPY --from=builder $GEM_HOME $GEM_HOME

RUN rm -rf /var/lib/apt/lists/* && \
   which cron && \
   rm -rf /etc/cron.*/*

COPY --from=builder $APP_ROOT/config/mawidabp_crontab /etc/cron.d/cronfile
RUN chmod 0644 /etc/cron.d/cronfile
RUN crontab /etc/cron.d/cronfile

RUN chown -R $USER: $APP_ROOT

WORKDIR $APP_ROOT

EXPOSE $PORT

CMD [ "bundle", "exec", "rails", "server" ]
