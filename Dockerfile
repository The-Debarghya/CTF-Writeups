# syntax=docker/dockerfile:1.2
# Base Image(debian, latest-stable)
FROM ubuntu:latest

# Update the system and install requirements
RUN apt-get update && apt-get upgrade -y
RUN apt-get install ruby bundler -y

# Setup Application Environment
WORKDIR /app
COPY Gemfile Gemfile.lock /app/
RUN gem install rack
RUN bundle install


COPY . /app
VOLUME /app/log
EXPOSE 4567/tcp 9292/tcp
CMD ["/usr/bin/bundle", "exec", "rackup", "--host", "0.0.0.0", "--port", "4567", "--env", "production"]
