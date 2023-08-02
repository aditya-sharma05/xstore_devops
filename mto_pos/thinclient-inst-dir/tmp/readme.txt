
This mto_pos/thinclient-inst-dir/tmp dir allows the Electron-based Xstore client app (for Thin Client) to
write an "anchor file", similar to the anchor files created by other Xstore-suite applications when started
with the "Wrapper".

The Electron-based client application is NOT a Java app, and thus cannot be managed with the Wrapper library.
Yet, we still wanted it to use anchor files similarly to the other Xstore Java apps on production systems.

So, the anchor-file functionality was built directly in to the Xstore Electron app.  Which means that, any
time you run xstore-electron, it needs to create an anchor file.

That is why this tmp directory must be here -- so that the the xstore-electron app can place its anchor file
in the expected location, which is:    {the installation directory}/tmp

A .pid file is also placed here and serves the same purpose as with other Wrapper apps.

Deleting the anchor file will kill the xstore-electron app.
