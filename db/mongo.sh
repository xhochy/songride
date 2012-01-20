#!/bin/sh
mongod --master --bind_ip 127.0.0.1 --port 27117 --dbpath mongo-store --noprealloc  --unixSocketPrefix mongo-sock --nohttpinterface

