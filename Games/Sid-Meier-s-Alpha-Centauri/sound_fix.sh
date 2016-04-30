#!/bin/bash -e
###
# This file is part of "./play.it Archlinux Edition".
# "./play.it Archlinux Edition" is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# "./play.it Archlinux Edition" is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with "./play.it Archlinux Edition".  If not, see <http://www.gnu.org/licenses/>. 2
###

###
# Sound fix for Sid Meier's Alpha Centauri. Basically automates the loading of "snd_pcm_oss" module.
#
# send your bug reports to vv221@dotslashplay.it or amadren@protonmail.ch if it's arch related
# start the e-mail subject by "./play.it" to avoid it being flagged as spam
###

###
# DON'T USE THIS SCRIPT IF THE SOUND WORKS
###

# Load snd_pcm_oss modules

if [[ -z "$(lsmod | grep -i "snd_pcm_oss" | head -1 | cut -c1-11)" ]]; then
	sudo modprobe snd_pcm_oss
	sudo touch /etc/modules-load.d/playit-snd_pcm_oss.conf
	sudo sh -c "echo \"snd_pcm_oss\" > /etc/modules-load.d/playit-snd_pcm_oss.conf"
fi
