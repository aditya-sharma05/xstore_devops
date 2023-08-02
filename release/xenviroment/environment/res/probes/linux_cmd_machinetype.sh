hal-device | grep system.hardware.product | sed -e s/.*.product\ \=\ // | sed -e s/\ \ \(string\)// | sed -e s/\'//g
