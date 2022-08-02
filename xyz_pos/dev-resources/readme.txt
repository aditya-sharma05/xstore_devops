This directory and its subdirectories can be used to store files that should be
managed by Subversion but not included in a build. For example:

* Development download files
* Documentation
* Utility SQL files
* High resolution logos
* WSDL/XSD/XML interface files
* Source/JavaDoc jar libraries

The contents of this directory will not be included in any build. Using this
location is preferable to a network share because this is versioned, and it is
possible to restore deleted files with minimal effort.
