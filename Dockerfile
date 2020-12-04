# Define global args
ARG FUNCTION_DIR="/home/app/"
ARG RUNTIME_VERSION="3.9"
ARG DISTRO_VERSION

# Stage 1 -bundle base image + runtime
# Grab a fresh copy of the image and install GCC
FROM python:${RUNTIME_VERSION}-alpine${DISTRO_VERSION} AS python-alpine
# Install GCC (Alpine uses musl but we compile and link dependencies with GCC)
RUN apk add --no-cache \libstdc++

# Stage 2 -build function and dependencies
FROM python-alpine AS build-image
# Install aws-lambda-cpp build dependencies
RUN apk add --no-cache \
build-base \
libtool \
autoconf \
automake \
libexecinfo-dev \
make \
cmake \
libcurl 
# Install AWS CLI
RUN pip install awscli
# Authenticating with AWS CLI
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_SESSION_TOKEN
ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
ENV AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}
# Include global args in this stage of the build
ARG FUNCTION_DIR
ARG RUNTIME_VERSION
# Create function directory
RUN mkdir -p ${FUNCTION_DIR}
# Copy handler function
COPY app/* ${FUNCTION_DIR}
RUN chmod +x ${FUNCTION_DIR}/run.sh
# Install the function's dependencies
RUN aws s3 cp s3://aws-lambda-runtime-clients/python/awslambdaruntimeclient-0.0.1.tar.gz awslambdaruntimeclient.tar.gz && \
python${RUNTIME_VERSION} -m pip install \
awslambdaruntimeclient.tar.gz \
--target ${FUNCTION_DIR}

# Stage 3 - Install httpd
# Grab a fresh copy of the Python image
FROM python-alpine
# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Set working directory to function root directory
WORKDIR ${FUNCTION_DIR}
# Copy in the built dependencies
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}
RUN pip install gunicorn
RUN pip install -r ${FUNCTION_DIR}/requirements.txt
ENTRYPOINT ["/home/app/run.sh"]
# CMD ["lambda"] - pass it in case it is run from Lambda environment