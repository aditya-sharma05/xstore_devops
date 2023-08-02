XSTORE SPRING CONFIGURATIONS - READ THIS FIRST!

Every Spring configuration file loaded by Xstore must have a unique file name. Unlike traditional Xstore
configs, creating a Spring file in this directory with the same name as a base Spring file will result in the 
ENTIRE base file being overridden by the new version.

For example, instead of creating a "spring.xml" file in this directory to define or override beans, name the 
file "mto-spring.xml" to ensure that all Spring file names remain unique. Adding a file named "spring.xml" to 
this directory will result in the base "spring.xml" file NOT LOADING and Xstore subsequently will likely not 
even start.

