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
logo="./logo.txt"
cat "$logo"
echo
titleLog "Welcome to Swarmpit"
log "Version: $VERSION"
log "Branch: $BRANCH"

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

INTERACTIVE=${INTERACTIVE:-1}
DEFAULT_STACK_NAME=${STACK_NAME:-swarmpit}
DEFAULT_APP_PORT=${APP_PORT:-888}
DEFAULT_DB_VOLUME_DRIVER=${DB_VOLUME_DRIVER:-local}

interactiveSetup() {
  ## Enter stack name
  while true
  do
    inputLog "Enter stack name [$DEFAULT_STACK_NAME]: "
    read stack_name
    STACK=${stack_name:=$DEFAULT_STACK_NAME}
    docker stack ps $STACK &> /dev/null
    if [ $? -eq 0 ]; then
      warningLog "Stack name [$STACK] is already taken!"
    else
      break
    fi
  done

  ## Enter application port
  inputLog "Enter application port [$DEFAULT_APP_PORT]: "
  read app_port
  PORT=${app_port:=$DEFAULT_APP_PORT}

  ## Enter database volume driver type
  inputLog "Enter database volume driver [$DEFAULT_DB_VOLUME_DRIVER]: "
  read db_driver
  VOLUME_DRIVER=${db_driver:=$DEFAULT_DB_VOLUME_DRIVER}
}

nonInteractiveSetup() {
  ## Stack name
  inputLog "Stack name: $DEFAULT_STACK_NAME"
  STACK=$DEFAULT_STACK_NAME
  docker stack ps $STACK &> /dev/null
  if [ $? -eq 0 ]; then
    warningLog "\nStack name [$STACK] is already taken!"
    errorLog "SETUP FAILED!"
    exit 1
  fi

  ## Application port
  inputLog "\nApplication port: $DEFAULT_APP_PORT "
  PORT=$DEFAULT_APP_PORT

  ## Database volume driver type
  inputLog "\nDatabase volume driver: $DEFAULT_DB_VOLUME_DRIVER"
  VOLUME_DRIVER=$DEFAULT_DB_VOLUME_DRIVER
}

if [ $INTERACTIVE -eq 1 ]; then
  interactiveSetup
else
  nonInteractiveSetup
fi

ARM=0
case $(uname -m) in
    arm*)    ARM=1 ;;
    aarch64) ARM=1 ;;
esac

if [ $ARM -eq 1 ]; then
    COMPOSE_FILE="swarmpit/docker-compose.arm.yml"
    max_attempts=56 # Wait up to ~ 4 minutes -> ((60[interval] + 10[timeout]) * 4[minutes]) / 5[sleep]
else
    COMPOSE_FILE="swarmpit/docker-compose.yml"
    max_attempts=28 # Wait up to ~ 2 minutes -> ((60[interval] + 10[timeout]) * 2[minutes]) / 5[sleep]
fi

sed -i "s|888:8080|$PORT:8080|" $COMPOSE_FILE
sed -i "s|driver:\ local|driver:\ $VOLUME_DRIVER|g" $COMPOSE_FILE

# MacOS
# sed -i "" "s|888:8080|$PORT:8080|" $COMPOSE_FILE
# sed -i "" "s|driver:\ local|driver:\ $VOLUME_DRIVER|g" $COMPOSE_FILE

successLog "DONE."

# DEPLOYMENT
sectionLog "\nApplication deployment"
docker stack deploy -c $COMPOSE_FILE $STACK
if [ $? -eq 0 ]; then
  successLog "DONE."
else
  errorLog "DEPLOYMENT FAILED!"
  exit 1
fi

# START
printf "\nStarting swarmpit..."
while true
do
  STATUS=$(curl --unix-socket /var/run/docker.sock -sgG -X GET http:/v1.24/tasks?filters="{\"service\":[\"${STACK}_app\"]}" | jq -r 'sort_by(.CreatedAt) | .[-1].Status.State')
  # Check whether status of the most recent task is running (Healthcheck passed)
  if [ "$STATUS" = "running" ]; then
    successLog "DONE."
    break
  else
    printf "."
    attempt_counter=$(($attempt_counter+1))
  fi
  if [ ${attempt_counter} -eq ${max_attempts} ]; then
      errorLog "FAILED!"
      warningLog "Swarmpit is not responding for a long time. Aborting installation...:(\nPlease check logs and cluster status for details."
      exit 1
  fi
  sleep 5
done

log "Swarmpit is running on port :$PORT"
titleLog "\nEnjoy :)"