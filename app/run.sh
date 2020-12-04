#!/bin/sh

echo "Starting initial load..."
if [ -z ${AWS_LAMBDA_RUNTIME_API} ]; then 
    echo "Running NOT IN Lambda execution environment" 
    echo "Executing other deployment specifc initialization code ..."
    # ECS/EKS/etc.
    gunicorn --bind 0.0.0.0:8000 application:app
else 
    echo "Running IN Lambda execution environment" 
    echo "Executing Lambda deployment specific initialization code ..."
    gunicorn --bind 0.0.0.0:8000 --daemon application:app 
    # Start lambda runtime client
    /usr/local/bin/python -m awslambdaruntimeclient lambda.handler
fi
