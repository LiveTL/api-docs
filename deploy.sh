#!/bin/bash

echo "pulling changes and building"
git pull
bundle exec middleman build

echo "removing old version and copying new"
rm -rf /opt/livetl-api-docs/*
cp -r ./build/* /opt/livetl-api-docs/

echo "done"
