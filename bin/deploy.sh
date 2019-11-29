#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo hugooooooooooooo
hugo

if [ $? != 0 ];
then
  echo -e "${RED}FAILED BUILDING~${NC}"
else
  cd public
  echo -e "${GREEN}[BUILD HUGO] Pulling from remote...${NC}"
  git pull
  echo -e "${GREEN}[BUILD HUGO] HEAD is up to date after pulling${NC}"
  if [ $? = 0 ];
  then
    MESSAGE=build@$(date +%s)
    echo -e "${GREEN}[BUILD HUGO] Commited: ${CYAN}$MESSAGE${NC}"
    git add . && \
      git commit -m $MESSAGE && \
      git push
    echo -e "${GREEN}[BUILD HUGO] Pushed to remote. DONE!${NC}"
  fi
fi
