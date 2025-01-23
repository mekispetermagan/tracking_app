#!/bin/bash

cd /home/peter/tracking/backend || exit 1
sudo pkill -9 gunicorn
nohup gunicorn -w 4 -b 127.0.0.1:5000 app:app &

