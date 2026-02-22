# Stage 1: Build the Flutter web app
FROM ghcr.io/cirruslabs/flutter:3.27.3 AS build-env

WORKDIR /app

# Add git safe directory config to prevent git errors in newer Flutter SDKs
RUN git config --global --add safe.directory /sdks/flutter

# Copy files to container
COPY . .

# Get packages and build web app
RUN flutter clean
RUN flutter pub get
RUN flutter build web --release

# Stage 2: Serve the app with Nginx
FROM nginx:alpine

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy build artifacts from previous stage
COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
