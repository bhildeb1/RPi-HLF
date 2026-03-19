#!/bin/bash

echo "use Ctrl + C to exit"

sudo journalctl -u fabric-ca.service -f
