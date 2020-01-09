#!/bin/bash

if [ -z "$1" ]; then

  echo Embed './Assets' folder into Assets.res file
  echo
  echo Add the next directive to FPC project file:
  echo
  echo "  {%BuildCommand pre-build.sh \$ProjPath()}"
  echo
  echo Then use the next Lazarus IDE menu to build Assets.res:
  echo
  echo "  Run / Build File"

else

  if [ $(uname -m) == 'x86_64' ]; then
    ARCH='64'
  else
    ARCH='32'
  fi

  ${1}../Tools/assetslz${ARCH} -GZ1 -B1 ${1}../Assets ${1}assets.tmp
  ${1}../Tools/resedit${ARCH} -D ${1}Assets.res rcdata ASSETS ${1}assets.tmp

fi