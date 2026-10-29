FROM postgres:18.1-bookworm AS postgres_tools

FROM ruby:4.0.6-slim-bookworm AS base
WORKDIR /rails
RUN apt-get update -qq && apt-get install --no-install-recommends -y curl libpq5 libvips42 postgresql-client && rm -rf /var/lib/apt/lists/*
COPY --from=postgres_tools /usr/lib/postgresql/18/bin/pg_dump /usr/local/bin/pg_dump
COPY --from=postgres_tools /usr/lib/x86_64-linux-gnu/libpq.so.5* /usr/lib/x86_64-linux-gnu/
ENV BUNDLE_PATH=/usr/local/bundle

FROM base AS dependencies
RUN apt-get update -qq && apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config && rm -rf /var/lib/apt/lists/*
COPY Gemfile Gemfile.lock ./
RUN bundle install && rm -rf /usr/local/bundle/ruby/*/cache

FROM dependencies AS test
RUN apt-get update -qq && apt-get install --no-install-recommends -y chromium chromium-driver && rm -rf /var/lib/apt/lists/*
ENV CHROME_BIN=/usr/bin/chromium SE_AVOID_STATS=true
COPY . .
ENV RAILS_ENV=test
CMD ["./bin/rails", "test"]

FROM dependencies AS build
ENV RAILS_ENV=production BUNDLE_WITHOUT=development:test
COPY . .
RUN bundle clean --force

FROM base AS production
ENV RAILS_ENV=production BUNDLE_WITHOUT=development:test RAILS_LOG_TO_STDOUT=1
RUN groupadd --system --gid 1000 rails && useradd rails --uid 1000 --gid 1000 --create-home
COPY --chown=rails:rails --from=build /usr/local/bundle /usr/local/bundle
COPY --chown=rails:rails --from=build /rails /rails
USER 1000:1000
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 6767
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "6767"]
