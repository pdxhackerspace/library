# syntax = docker/dockerfile:1

ARG RUBY_VERSION=4.0.5
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim AS base
ARG RUBY_VERSION=4.0.5
RUN test "$(ruby -e 'print RUBY_VERSION')" = "${RUBY_VERSION}" || \
    (echo "Expected Ruby ${RUBY_VERSION}, got $(ruby -v)" >&2; exit 1)

WORKDIR /rails

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

FROM base AS build

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl git libpq-dev libvips node-gyp pkg-config python-is-python3 libyaml-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ARG NODE_VERSION=24.9.0
ARG YARN_VERSION=latest
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    npm install -g yarn@$YARN_VERSION && \
    rm -rf /tmp/node-build-master

COPY Gemfile Gemfile.lock ./
RUN --mount=type=cache,target=/root/.bundle/cache \
    bundle lock --add-platform x86_64-linux && \
    bundle install && \
    rm -rf "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY package.json yarn.lock ./
RUN --mount=type=cache,target=/root/.yarn \
    --mount=type=cache,target=/root/.cache \
    yarn install --frozen-lockfile

COPY . .

RUN bundle exec bootsnap precompile app/ lib/

RUN --mount=type=cache,target=/rails/tmp/cache \
    SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

FROM base
ARG APP_VERSION=dev
ENV APP_VERSION=$APP_VERSION

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libvips postgresql-client libyaml-0-2 tzdata zbar-tools && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER rails:rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 3000
CMD ["./bin/rails", "server"]
