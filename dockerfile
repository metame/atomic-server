FROM node:20 as js-builder
WORKDIR /app/browser
ENV SHELL=bash
RUN npm install -g pnpm
COPY browser/package.json browser/pnpm-lock.yaml ./
RUN pnpm install -r --frozen-lockfile
COPY ./browser .
RUN pnpm install -r --frozen-lockfile
RUN pnpm build

FROM rust:latest as builder
WORKDIR /app
COPY . .
COPY --from=js-builder /app/browser/data-browser/dist /app/browser/data-browser/dist
# git-fetch-with-cli is a CI bugfix, we should be able to remove it later
RUN cargo build --release --bin atomic-server --config net.git-fetch-with-cli=true

# We only need a small runtime for this step
FROM rust:latest as runtime
COPY --chmod=0755 --from=builder /app/target/release/atomic-server /atomic-server-bin
# For a complete list of possible ENV vars or available flags, run with `--help`
ENV ATOMIC_STORE_PATH="/atomic-storage/db"
ENV ATOMIC_CONFIG_PATH="/atomic-storage/config.toml"
ENV ATOMIC_PORT="80"
EXPOSE 80
VOLUME /atomic-storage
ENTRYPOINT ["/atomic-server-bin"]
