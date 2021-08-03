#!/bin/bash

function copy_init_conf() {
  set -e
  local directory=$1
  mkdir -pv /opt/sap/scc-config/${directory}
  cp -rfv /opt/sap/scc-init/${directory} /opt/sap/scc-config/
  set +e
}

function create_config_symlink() {
  set -e
  local directory=$1
  if [ ! -L /opt/sap/scc/${directory} ]; then
    echo "creating symlink for ${directory}"
    rm -rfv /opt/sap/scc/${directory}
    ln -s /opt/sap/scc-config/${directory} /opt/sap/scc/${directory}
  else
    echo "symlink already exists for ${directory}"
  fi

  set +e

}


function init_scc() {
	echo "Init SAP Cloud Connector for persistency as user: $(id)"
	copy_init_conf conf
	copy_init_conf config
	copy_init_conf config_master
	copy_init_conf configuration
	copy_init_conf scc_config
}


if [ ! -d /opt/sap/scc-config/scc_config ]; then
  echo "SAP Cloud connector not initialized, performing init"
  init_scc
else
  echo "SAP Cloud connector already initialized"
fi

create_config_symlink conf
create_config_symlink config
create_config_symlink config_master
create_config_symlink configuration
create_config_symlink scc_config

if [ "x$SAP_SCC_BASE_DIR" = "x" ]; then
  export SAP_SCC_BASE_DIR=/opt/sap/scc
fi

if [ "x$SAP_SCC_PORT" = "x" ]; then
  echo "env variable SAP_SCC_PORT not set, default to 8443"
  export SAP_SCC_PORT=443
fi

# change the port
cd $SAP_SCC_BASE_DIR
java -jar $SAP_SCC_BASE_DIR/configurator.jar -port $SAP_SCC_PORT

JAVA_DEFAULT_OPTS="-server -XX:+UseContainerSupport"
# JAVA_DEFAULT_OPTS="$JAVA_DEFAULT_OPTS -XX:MaxNewSize=512m -XX:NewSize=512m -XX:+UseConcMarkSweepGC -XX:TargetSurvivorRatio=85 -XX:SurvivorRatio=6"
JAVA_DEFAULT_OPTS="$JAVA_DEFAULT_OPTS -Dorg.apache.tomcat.util.digester.PROPERTY_SOURCE=com.sap.scc.tomcat.utils.PropertyDigester -Dosgi.requiredJavaVersion=1.6"
JAVA_DEFAULT_OPTS="$JAVA_DEFAULT_OPTS -Dosgi.install.area=.  -DuseNaming=osgi -Dorg.eclipse.equinox.simpleconfigurator.exclusiveInstallation=false -Dcom.sap.core.process=ljs_node"
JAVA_DEFAULT_OPTS="$JAVA_DEFAULT_OPTS -Declipse.ignoreApp=true -Dosgi.noShutdown=true -Dosgi.framework.activeThreadType=normal -Dosgi.embedded.cleanupOnSave=true -Dosgi.usesLimit=30"
JAVA_DEFAULT_OPTS="$JAVA_DEFAULT_OPTS -Djava.awt.headless=true -Dio.netty.recycler.maxCapacity.default=256"


exec $SAP_SCC_BASE_DIR/go.sh

