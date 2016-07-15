#!/bin/bash
/root/run_service.sh &
cd /root/faraday
yes | ./faraday.py --gui=no-gui --update
yes | ./faraday.py --gui=no-gui --update
