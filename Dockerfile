FROM __PLATFORM_NAME__:__PLATFORM_VERSION__

# Head declarations
MAINTAINER Thomas Orozco <thomas@scalr.com>

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

ADD ./build/__PLATFORM_NAME__ /local_build_scripts

RUN /local_build_scripts/bootstrap.sh

RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import - && \
    curl -sSL https://get.rvm.io | bash -s stable --ruby && \
    rm -rf /var/lib/apt/lists/* || true && \
    yum clean all || true

RUN /local_build_scripts/install_utils.sh

RUN bash --login -c "gem install package_cloud bundler berkshelf"

ADD ./Gemfile /builder/Gemfile
RUN bash --login -c "cd /builder && bundle install --binstubs"

ADD . /builder
ENTRYPOINT ["/builder/build/shared/entrypoint.sh"]
CMD ["/builder/build/shared/build.sh"]
