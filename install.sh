#!/bin/bash
  
GC='\033[0;32m' #green color
RC='\033[0;31m' #red color
OC='\033[0;33m' #orange color
NC='\033[0m' #no color
IC='\033[0;37m' #input text
BC='\033[1m' #bold text
UC='\033[4m' #underline text

function successLog { echo -e "${GC}$1${NC}"; }
function warningLog { echo -e "${OC}$1${NC}"; }
function errorLog { echo -e "${RC}$1${NC}"; }
function inputLog { printf "${IC}$1${NC}"; }
function titleLog { echo -e "${BC}$1${NC}"; }
function sectionLog { echo -e "${UC}$1${NC}"; } 
function log { echo -e "$1"; }

BRANCH=$VERSION

if [ "$VERSION" = 'edge' ]; then
    BRANCH=master
fi

# INFO
figlet swarmpit
titleLog "Welcome to Swarmpit"
log "Version: $VERSION"
log "Branch: $BRANCH"

# DEPENDENCIES
sectionLog "\nPreparing dependencies"
docker pull byrnedo/alpine-curl:latest
if [ $? -eq 0 ]; then
    successLog "DONE."
else
    errorLog "PREPARATION FAILED!"
    exit 1
fi

# INSTALLATION
sectionLog "\nPreparing installation"
git clone https://github.com/swarmpit/swarmpit -b $BRANCH
if [ $? -eq 0 ]; then
    successLog "DONE."
else
    errorLog "PREPARATION FAILED!"
    exit 1
fi

# SETUP
sectionLog "\nApplication setup"

## Enter stack name
while true
do
  inputLog "Enter stack name [swarmpit]: "
  read stack_name
  STACK=${stack_name:-swarmpit}
  docker stack ps $STACK &> /dev/null
  if [ $? -eq 0 ]; then
    warningLog "Stack name [$STACK] is already taken!"
  else
    break
  fi
done

## Enter application port
inputLog "Enter application port [888]: "
read app_port
APP_PORT=${app_port:-888}
sed -i 's/888/'"$APP_PORT"'/' swarmpit/docker-compose.yml

## Enter database volume type
inputLog "Enter database volume type [local]: "
read db_volume
DB_VOLUME=${db_volume:-local}
sed -i 's/driver: local/'"driver: $DB_VOLUME"'/' swarmpit/docker-compose.yml

## Enter admin user
inputLog "Enter admin username [admin]: "
read admin_username
ADMIN_USER=${admin_username:-admin}

## Enter admin passwd
while [[ ${#admin_password} -lt 8 ]]; do
    inputLog "Enter admin password (min 8 characters long): "
    read admin_password
done
ADMIN_PASS=${admin_password}

successLog "DONE."

# DEPLOYMENT
sectionLog "\nApplication deployment"
docker stack deploy -c swarmpit/docker-compose.yml $STACK
if [ $? -eq 0 ]; then
  successLog "DONE."
else
  errorLog "DEPLOYMENT FAILED!"
  exit 1
fi

# START
printf "\nStarting swarmpit..."
SWARMPIT_NETWORK="${STACK}_net"
SWARMPIT_VERSION_URL="http://${STACK}_app:8080/version"
while true
do
  STATUS=$(docker run --rm --network $SWARMPIT_NETWORK byrnedo/alpine-curl -s -o /dev/null -w '%{http_code}' $SWARMPIT_VERSION_URL)
  if [ $STATUS -eq 200 ]; then
    successLog "DONE."
    break
  else
    printf "."
  fi
  sleep 5
done

# INITIALIZATION
printf "Initializing swarmpit..."
SWARMPIT_INITIALIZE_URL="http://${STACK}_app:8080/initialize"
STATUS=$(docker run --rm --network $SWARMPIT_NETWORK byrnedo/alpine-curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' $SWARMPIT_INITIALIZE_URL -d '{"username": "'"$ADMIN_USER"'", "password": "'"$ADMIN_PASS"'"}')
if [ $STATUS -eq 201 ]; then
  successLog "DONE."
  sectionLog "\nSummary"
  log "Username: $ADMIN_USER"
  log "Password: $ADMIN_PASS"
else
  warningLog "SKIPPED.\nInitialization was already done in previous installation.\nPlease use your old admin credentials to login or drop swarmpit database volume for clean installation."
  sectionLog "\nSummary"
fi

log "Swarmpit is running on port :$APP_PORT"
titleLog "\nEnjoy :)"
