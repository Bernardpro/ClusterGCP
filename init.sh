#!/bin/bash

# 1 Build the Docker images
cd sample-app-master
docker compose up --build -d

# 2 Apply migrations
docker exec -it sample-app-master-1 app php artisan migrate
