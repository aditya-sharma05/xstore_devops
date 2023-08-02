When using Epson devices on Windows, the following steps should be followed (using files in the windows_64 folder):
1) Extract the TMUSB zip and run the Setup.exe file to install the latest TMUSB driver using and administrative account.
2) Extract the PCS zip and run the PCS64.msi file to install the port communications service using an administrative account.

When using Epson devices on Linux, the following steps should be followed (using files in the linux_64 folder):
1) If PCS is installed from a prior level uninstall the PCS RPM.
2) Extract the PCS tarball and run pcsinstall.sh as root.

Independent of the platform that is being used, if a serial printer will need to be used, please review readme_serial.txt for additional details.