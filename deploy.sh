#!/bin/bash

echo "pulling changes and building"
git pull
bundle exec middleman build

echo "removing old version and copying new"
sudo rm -rf /opt/livetl-api-docs/*
sudo cp -r ./build/* /opt/livetl-api-docs/
sudo chown -R www-data:www-data /opt/livetl-api-docs/

echo "done"
