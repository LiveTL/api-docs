#!/bin/bash

echo "pulling changes and building"
git pull
bundle exec middleman build

echo "removing old version and copying new"
sudo rm -rf /opt/livetl-docs/api/*
sudo cp -r ./build/* /opt/livetl-docs/api/
sudo chown -R www-data:www-data /opt/livetl-docs/

echo "done"
