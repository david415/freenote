#!/usr/bin/env bash

set -ex

main() {
  # Your audio device
  # Find the correct audio device with with `pactl list`
  : ${AUDIODEVICE:=alsa_input.usb-046d_0825_6879E360-02-U0x46d0x825.analog-mono}
  : ${VIDEODEVICE:=/dev/video0}
  #
  # Specify the interface and port of the Tor Hidden Service
  : ${LOCALIP:=127.0.0.1}
  : ${LOCALPORT:=8080}
  : ${FRAMERATE:=10}
  echo $AUDIODEVICE
  stream
}

# Audio and video streaming on Tor Hidden Service
stream() {
  gst-launch-0.10 \
  v4l2src ! \
  video/x-raw-yuv,device="$VIDEODEVICE",width="640,height=480,framerate=(fraction)$FRAMERATE/1" ! queue ! \
  ffmpegcolorspace ! tee name=localview ! theoraenc ! queue ! \
  oggmux name=mux \
  pulsesrc device="$AUDIODEVICE" ! queue ! \
  audioconvert ! vorbisenc ! queue ! mux. \
  mux. ! queue ! tcpserversink  host="$LOCALIP" port="$LOCALPORT" \
  localview. ! queue ! xvimagesink sync=false
}

[ "${BASH_SOURCE[0]}" == "$0" ] && main "$@"
:
