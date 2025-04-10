#!/bin/ash
# Velocity Installation Script
#
# Server Files: /mnt/server
PROJECT=velocity


if [ -n "${DL_PATH}" ]; then
	echo -e "Using supplied download url: ${DL_PATH}"
	DOWNLOAD_URL=`eval echo $(echo ${DL_PATH} | sed -e 's/{{/${/g' -e 's/}}/}/g')`
else
	VER_EXISTS=`curl -s https://api.papermc.io/v2/projects/${PROJECT} | jq -r --arg VERSION $VELOCITY_VERSION '.versions[] | contains($VERSION)' | grep -m1 true`
	LATEST_VERSION=`curl -s https://api.papermc.io/v2/projects/${PROJECT} | jq -r '.versions' | jq -r '.[-1]'`

	if [ "${VER_EXISTS}" == "true" ]; then
		echo -e "Version is valid. Using version ${VELOCITY_VERSION}"
	else
		echo -e "Specified version not found. Defaulting to the latest ${PROJECT} version"
		MINECRAFT_VERSION=${LATEST_VERSION}
	fi

	BUILD_EXISTS=`curl -s https://api.papermc.io/v2/projects/${PROJECT}/versions/${VELOCITY_VERSION} | jq -r --arg BUILD ${BUILD_NUMBER} '.builds[] | tostring | contains($BUILD)' | grep -m1 true`
	LATEST_BUILD=`curl -s https://api.papermc.io/v2/projects/${PROJECT}/versions/${VELOCITY_VERSION} | jq -r '.builds' | jq -r '.[-1]'`

	if [ "${BUILD_EXISTS}" == "true" ]; then
		echo -e "Build is valid for version ${MINECRAFT_VERSION}. Using build ${BUILD_NUMBER}"
	else
		echo -e "Using the latest ${PROJECT} build for version ${MINECRAFT_VERSION}"
		BUILD_NUMBER=${LATEST_BUILD}
	fi

	JAR_NAME=${PROJECT}-${VELOCITY_VERSION}-${BUILD_NUMBER}.jar

	echo "Version being downloaded"
	echo -e "Velocity Version: ${VELOCITY_VERSION}"
	echo -e "Build: ${BUILD_NUMBER}"
	echo -e "JAR Name of Build: ${JAR_NAME}"
	DOWNLOAD_URL=https://api.papermc.io/v2/projects/${PROJECT}/versions/${VELOCITY_VERSION}/builds/${BUILD_NUMBER}/downloads/${JAR_NAME}
fi

cd /mnt/server

echo -e "Running curl -o ${SERVER_JARFILE} ${DOWNLOAD_URL}"

if [ -f ${SERVER_JARFILE} ]; then
	mv ${SERVER_JARFILE} ${SERVER_JARFILE}.old
fi

curl -o ${SERVER_JARFILE} ${DOWNLOAD_URL}

if [[ -f velocity.toml ]]; then
echo -e "velocity config file exists"
else
echo -e "downloading velocity config file."
curl https://raw.githubusercontent.com/NicoStraube/pterodactyl-resources/refs/heads/master/papermc/velocity/velocity.toml -o velocity.toml
fi

if [[ -f proxy-fwd.secret ]]; then
echo -e "velocity forwarding secret file already exists"
else
echo -e "creating forwarding secret file"
touch proxy-fwd.secret
date +%s | sha256sum | base64 | head -c 12 > proxy-fwd.secret
fi

echo -e "install complete"
