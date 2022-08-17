Serial printers are not registered automatically with the Port Communication Service.  To register a serial port for use with the Epson jPOS driver, please follow the instructions below:

1) Copy an appropriate pcs.properties file to the port communication service's configuration directory.
 - If the platform is Windows, a sample file can be found in serial_windows.
 - If the platform is Linux, a sample file can be found in serial_linux.
 - If an older variant of Windows (ie. XP or similar) is being used, the configuration directory for the port communication service is C:\Documents and Settings\All Users\Application Data\epson\portcommunicationservice.
 - If a newer variant Windows (ie. Vista or newer) is being used, the configuration directory for the port communication service is c:\Users\All Users\epson\portcommunicationservice.
 - If Linux is being used, the configuration directory for the port communication service is /var/epson_pcs/portcommunicationservice
2) Configure the pcs.properties that was copied appropriately for the platform
 - Serial port name, baud rate, etc. should be set properly for the printer.