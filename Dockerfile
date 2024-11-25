FROM ruby:2.7.1
RUN apt-get update -qq \
  && apt-get install -y build-essential nodejs locales apt-utils graphviz vim \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle install -j3 --no-deployment

ENV TZ=Asia/Tokyo
RUN echo "${TZ}" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
RUN localedef -f UTF-8 -i en_US en_US.utf8


ADD . /app