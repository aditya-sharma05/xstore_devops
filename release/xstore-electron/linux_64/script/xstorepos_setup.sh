#! /bin/sh

XSTORE_DESKTOP_FILENAME=Xstore.desktop

LOCAL_SHARE_APPS=~/.local/share/applications

XSTOREPOS_MIMETYPE=x-scheme-handler/xstorepos


echo Copying $XSTORE_DESKTOP_FILENAME to $LOCAL_SHARE_APPS
cp $XSTORE_DESKTOP_FILENAME $LOCAL_SHARE_APPS

# The xdg-mime command doesn't seem to work unless you first cd to this location
cd ~/.local/share/applications

echo Registering Xstore mime-type $XSTOREPOS_MIMETYPE
xdg-mime default Xstore.desktop x-scheme-handler/xstorepos
