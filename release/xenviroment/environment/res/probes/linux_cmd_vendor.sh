hal-device | grep system.hardware.vendor | awk '{print $3}' | sed s/\'//g
