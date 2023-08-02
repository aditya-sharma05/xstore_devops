#!/bin/sh
#
# Copies a new JRE into place.  Expects a decompressed JRE directory that can simply be moved into place.
#


####
#### Set up environment variables
####
SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ENVIRONMENT_DIRECTORY=$(cd "${SCRIPT_DIRECTORY}/.." && pwd)
ENV_DATA_DIR=${ENVIRONMENT_DIRECTORY}/../xstoredata/environment
JRE_DIRECTORY=$(cd "${ENVIRONMENT_DIRECTORY}/../jre" && pwd)
JAVA_HOME=${JRE_DIRECTORY}
JRE_UPDATE_DIRECTORY=${ENV_DATA_DIR}/jre_update
PREVIOUS_JRE_DIRECTORY=${ENV_DATA_DIR}/jre_previous
ENV_MARKER_DIRECTORY=${ENV_DATA_DIR}/marker
ERR_MARKER_FILE=${ENV_MARKER_DIRECTORY}/jre_update.err
JRE_UPDATE_APPLIED_MARKER=${ENV_MARKER_DIRECTORY}/jre_update_applied.xst
ENV_UPDATE_APPLIED_MARKER=${ENV_MARKER_DIRECTORY}/env_upgrade_applied.xst
ENV_UPDATE_DIRECTORY=${ENV_DATA_DIR}/prestart_updates
ENV_UPDATE_DIRECTORY_OLD=${ENVIRONMENT_DIRECTORY}/prestart_updates
LOG_FILE=${ENV_DATA_DIR}/log/update_jre.log

rm -f ${LOG_FILE}.005
mv ${LOG_FILE}.004 ${LOG_FILE}.005
mv ${LOG_FILE}.003 ${LOG_FILE}.004
mv ${LOG_FILE}.002 ${LOG_FILE}.003
mv ${LOG_FILE}.001 ${LOG_FILE}.002
mv ${LOG_FILE} ${LOG_FILE}.001

logger () {
  echo \[`date`\] $*
  echo \[`date`\] $* >> ${LOG_FILE}
}

handle_error() {

  if [ $1 -ne 0 ]; then
    logger $2*
    echo "JRE update failed: \n\n $2*" > ${ERR_MARKER_FILE}
    exit $1
  fi
}

xenv_upgrade() {
  logger "=========================================="
  logger "Looking for Xenvironment upgrades..."
  logger "=========================================="

  if [ -d ${ENV_UPDATE_DIRECTORY_OLD} ]; then
    for UPGRADE_JAR in ${ENV_UPDATE_DIRECTORY_OLD}/*.jar; do
      if [ -f ${UPGRADE_JAR} ]; then
        logger "===================================================================="
        logger "Running Xenvironment update ${UPGRADE_JAR}"
        logger "===================================================================="
        rm -f ${ENVIRONMENT_DIRECTORY}/tmp/xenv_ui.anchor
        mv ${UPGRADE_JAR} /tmp
        mv ${UPGRADE_JAR}.applyTrack ${ENV_MARKER_DIRECTORY}
        touch ${ENV_UPDATE_APPLIED_MARKER}
        ${JAVA_HOME}/bin/java -Dreboot.when.finished=true -Ddont.launch.xenvironment=true -Ddont.stop.xenvironment=true -jar /tmp/$(basename ${UPGRADE_JAR})
        rm -f ${UPGRADE_JAR}
      fi
    done
  fi

  if [ -d ${ENV_UPDATE_DIRECTORY} ]; then
    for UPGRADE_JAR in ${ENV_UPDATE_DIRECTORY}/*.jar; do
      if [ -f ${UPGRADE_JAR} ]; then
        logger "===================================================================="
        logger "Running Xenvironment update ${UPGRADE_JAR}"
        logger "===================================================================="
        rm -f ${ENVIRONMENT_DIRECTORY}/tmp/xenv_ui.anchor
        mv ${UPGRADE_JAR} /tmp
        mv ${UPGRADE_JAR}.applyTrack ${ENV_MARKER_DIRECTORY}
        touch ${ENV_UPDATE_APPLIED_MARKER}
        ${JAVA_HOME}/bin/java -Dreboot.when.finished=true -Ddont.launch.xenvironment=true -Ddont.stop.xenvironment=true -jar /tmp/$(basename ${UPGRADE_JAR})
        rm -f ${UPGRADE_JAR}
      fi
    done
  fi
}

####
#### Remove the previous log file
####
rm -f ${LOG_FILE}

####
#### Check if JRE update directory is set.
####
if [[ -z ${JRE_UPDATE_DIRECTORY} || ${#JRE_UPDATE_DIRECTORY} -lt 5 ]]; then
  handle_error 1 "JRE update directory is not set correctly."
fi

####
#### Check if JRE directory is set.
####
if [[ -z ${JRE_DIRECTORY} || ${#JRE_DIRECTORY} -lt 5 ]]; then
  handle_error 1 "JRE directory is not set correctly."
fi

####
#### Check if the configured JRE directory exists.
####
if [[ ! -d ${JRE_DIRECTORY} ]]; then
  handle_error 1 "JRE directory at ${JRE_DIRECTORY} not found!"
fi

####
#### Exit if no JRE to apply.
####
if [[ ! -d ${JRE_UPDATE_DIRECTORY}/jre ]]; then
  logger No JRE to apply.
  xenv_upgrade
  exit 0
fi

####
#### Remove previous JRE if it's there
####
if [ -d ${PREVIOUS_JRE_DIRECTORY} ]; then
  logger Removing contents of old JRE directory ${PREVIOUS_JRE_DIRECTORY}
  rm -rf ${PREVIOUS_JRE_DIRECTORY}/*
  # Exit right now if this fails.
  handle_error $? "Unable to remove previous JRE directory."
else
  logger No previous JRE directory found at ${PREVIOUS_JRE_DIRECTORY}
fi

####
#### Move the JRE contents to the previous directory
####
logger Moving everything in ${JRE_DIRECTORY} to ${PREVIOUS_JRE_DIRECTORY}
if [[ ! -d ${PREVIOUS_JRE_DIRECTORY} ]]; then
  mkdir -p ${PREVIOUS_JRE_DIRECTORY}
  handle_error $? "Unable to create directory ${PREVIOUS_JRE_DIRECTORY}"
fi
mv ${JRE_DIRECTORY}/* ${PREVIOUS_JRE_DIRECTORY}
handle_error $? "Unable to move contents of current JRE directory ${JRE_DIRECTORY} to ${PREVIOUS_JRE_DIRECTORY}"

####
#### Move the new JRE into place
####
logger Moving the new JRE into place from ${JRE_UPDATE_DIRECTORY}/jre to ${JRE_DIRECTORY}
mv ${JRE_UPDATE_DIRECTORY}/jre/* ${JRE_DIRECTORY}
if [ $? -ne 0 ]; then
  logger "Something went wrong moving new files into place. Attempting to recover!"
  # Try to restore the previous jre.
  rm -rf ${JRE_DIRECTORY}/*
  cp -R ${PREVIOUS_JRE_DIRECTORY}/* ${JRE_DIRECTORY}

  rm -rf ${JRE_UPDATE_DIRECTORY}/jre
  handle_error $? "Something went wrong moving new files into place, recovery was attempted."
fi

if [ ! -f ${JRE_DIRECTORY}/bin/xenv_eng ] ; then
cp ${JRE_DIRECTORY}/bin/java ${JRE_DIRECTORY}/bin/xenv_eng
fi

if [ ! -f ${JRE_DIRECTORY}/bin/xenv_ui ] ; then
cp ${JRE_DIRECTORY}/bin/java ${JRE_DIRECTORY}/bin/xenv_ui
fi

####
#### Set up permissions on the bin folder
####
logger Making everything in ${JRE_DIRECTORY}/bin executable...
chmod 755 ${JRE_DIRECTORY}/bin/*
handle_error $? "Unable to update permissions in ${JRE_DIRECTORY}/bin"

logger Removing JRE update from source ${JRE_UPDATE_DIRECTORY}
rm -rf ${JRE_UPDATE_DIRECTORY}/jre
handle_error $? "Unable to remove ${JRE_UPDATE_DIRECTORY}/jre"

rm -f ${ERR_MARKER_FILE}
mv ${JRE_UPDATE_DIRECTORY}/*.applyTrack ${ENV_MARKER_DIRECTORY}
touch ${JRE_UPDATE_APPLIED_MARKER}

xenv_upgrade

exit 0
