FROM rust:1.63 as build

RUN apt-get update && apt-get -y install protobuf-compiler

# create a new empty shell project
RUN USER=root mkdir -p /usr/src && cd /usr/src && cargo new --bin kvapp
WORKDIR /usr/src/kvapp

# copy over your manifests
COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml
RUN cp src/main.rs src/tester.rs

# this build step will cache your dependencies
RUN cargo update && cargo fetch
RUN cargo build --release
RUN rm src/*.rs

# copy your source tree
COPY ./src ./src

# build for release
RUN rm ./target/release/deps/kvapp* ./target/release/deps/tester*
RUN cargo build --release

FROM debian:buster-slim

COPY --from=build /usr/src/kvapp/target/release/kvapp .
COPY ./example-cfg-kvapp.json ./cfg-kvapp.json

CMD ["./kvapp", "--bind-addr", "0.0.0.0"]