#!/usr/bin/env bash

set -ex

main() {
  # Your audio device
  # Find the correct audio device with with `pactl list`
  : ${AUDIODEVICE:=alsa_input.usb-046d_0825_6879E360-02-U0x46d0x825.analog-mono}
  : ${VIDEODEVICE:=/dev/video0}
  : ${FRAMERATE:=10}
  #
  : ${VIDEO_USER:="robot"}
  : ${VIRTENV_PY:="/home/human/projects/virtualenv-1.11.x/virtualenv.py"}
  : ${HIDDEN_SERVICE_DIR:="/home/$VIDEO_USER/hidden_service"}
  : ${ROBOTVIRTENV:="/home/$VIDEO_USER/virtenv_robot"}
  : ${HIDDEN_WEB_DIR:="/home/$VIDEO_USER/hidden_webdir"}
  : ${VIDEO_FILENAME:="video-`date +%s`.ogv"}
  : ${WEB_VIDEO_LOCATION:="$HIDDEN_WEB_DIR/$VIDEO_FILENAME"}
  #
  echo
  echo $WEB_VIDEO_LOCATION
  echo $AUDIODEVICE
  echo

  create_robot_user

  #run_tor_hidden_service

  stream
}

create_robot_user() {
  id -u $VIDEO_USER &>/dev/null || sudo useradd $VIDEO_USER
  sudo mkdir -p /home/$VIDEO_USER
  sudo chown $VIDEO_USER:$VIDEO_USER /home/$VIDEO_USER
  sudo -u $VIDEO_USER $VIRTENV_PY $ROBOTVIRTENV
}

run_tor_hidden_service() {

  sudo -u $VIDEO_USER mkdir -p $HIDDEN_WEB_DIR
  sudo -u $VIDEO_USER chmod 770 $HIDDEN_WEB_DIR
  sudo chgrp `id -g` $HIDDEN_WEB_DIR

  sudo -u $VIDEO_USER bash -c ". $ROBOTVIRTENV/bin/activate ; usewithtor pip install txtorcon"
#  sudo -u $VIDEO_USER bash -c ". $ROBOTVIRTENV/bin/activate ; usewithtor pip install git+https://github.com/meejah/txtorcon.git"

  sudo -u $VIDEO_USER bash -c "mkdir -p $HIDDEN_SERVICE_DIR"
  sudo -u $VIDEO_USER bash -c ". $ROBOTVIRTENV/bin/activate ; cd ; twistd web --port "onion:80:hiddenServiceDir=$HIDDEN_SERVICE_DIR" --path $WEB_VIDEO_LOCATION"

  #onion=$(sudo -u $VIDEO_USER cat $HIDDEN_SERVICE_DIR/hostname)
  #echo "your video stream onion is $onion"
  echo "find your onion address in $HIDDEN_SERVICE_DIR/hostname after tor boots up..."
}

# Audio and video streaming on Tor Hidden Service
stream() {

  sudo -u $VIDEO_USER touch $WEB_VIDEO_LOCATION
  sudo -u $VIDEO_USER chmod 770 $WEB_VIDEO_LOCATION
  sudo chgrp `id -g` $WEB_VIDEO_LOCATION

  gst-launch-0.10 \
  v4l2src ! \
  video/x-raw-yuv,device="$VIDEODEVICE",width="640,height=480,framerate=(fraction)$FRAMERATE/1" ! queue ! \
  ffmpegcolorspace ! tee name=localview ! theoraenc ! queue ! \
  oggmux name=mux \
  pulsesrc device="$AUDIODEVICE" ! queue ! \
  audioconvert ! vorbisenc ! queue ! mux. \
  mux. ! queue ! filesink sync=false location="$WEB_VIDEO_LOCATION" \
  localview. ! queue ! xvimagesink sync=false
}

[ "${BASH_SOURCE[0]}" == "$0" ] && main "$@"
:
