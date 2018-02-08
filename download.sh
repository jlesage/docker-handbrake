#! /bin/bash
if [ "$HANDBRAKE_VERSION" = "github" ]; then
  git clone https://github.com/HandBrake/HandBrake.git;
else
  curl -# -L https://download.handbrake.fr/releases/${HANDBRAKE_VERSION}/HandBrake-${HANDBRAKE_VERSION}.tar.bz2 | tar xj;
fi
