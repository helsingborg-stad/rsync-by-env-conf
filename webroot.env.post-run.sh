#!/bin/bash
rm -rf /var/www/prod/wp-content/uploads/cache/*
redis-cli flushall