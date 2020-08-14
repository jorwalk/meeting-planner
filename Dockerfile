# The tag here should match the Meteor version of your app, per .meteor/release
FROM geoffreybooth/meteor-base:1.10.2

RUN groupadd --gid 5000 newuser \
    && useradd --home-dir /home/newuser --create-home --uid 5000 \
    --gid 5000 --shell /bin/sh --skel /dev/null newuser


# Copy app package.json and package-lock.json into container
COPY package*.json $APP_SOURCE_FOLDER/
RUN chown newuser /opt/src
RUN mkdir /opt/src/.meteor && mkdir /opt/src/.meteor/local && chown newuser /opt/src/.meteor/local
RUN mkdir /opt/bundle && chown newuser /opt/bundle
RUN chown newuser /docker/build-meteor-bundle.sh
USER newuser
RUN bash $SCRIPTS_FOLDER/build-app-npm-dependencies.sh

# Copy app source into container
COPY . $APP_SOURCE_FOLDER/
RUN bash $SCRIPTS_FOLDER/build-meteor-bundle.sh


# Use the specific version of Node expected by your Meteor release, per https://docs.meteor.com/changelog.html; this is expected for Meteor 1.10.2
FROM node:12.16.1-alpine
ENV APP_BUNDLE_FOLDER /opt/bundle
ENV SCRIPTS_FOLDER /docker

# Runtime dependencies; if your dependencies need compilation (native modules such as bcrypt) or you are using Meteor <1.8.1, use app-with-native-dependencies.dockerfile instead
RUN apk --no-cache add \
    bash \
    ca-certificates

# Copy in entrypoint
COPY --from=0 $SCRIPTS_FOLDER $SCRIPTS_FOLDER/

# Copy in app bundle
COPY --from=0 $APP_BUNDLE_FOLDER/bundle $APP_BUNDLE_FOLDER/bundle/

RUN bash $SCRIPTS_FOLDER/build-meteor-npm-dependencies.sh

# Start app
ENTRYPOINT ["/docker/entrypoint.sh"]

CMD ["node", "main.js"]