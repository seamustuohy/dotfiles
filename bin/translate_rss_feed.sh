#!/usr/bin/env bash
#
# Copyright © 2021 seamus tuohy, <code@seamustuohy.com>
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the included LICENSE file for details.

temp="/tmp/RSS/feed.rss"

flushpipe() {
 # wait until the next line becomes available
 read -d "" buffer
 # consume any remaining elements — a small timeout ensures that
 # rapidly fired events are batched together
 while read -d "" -t 1 line; do buffer="$buffer\n$line"; done
 echo $buffer
}

flushpipe  > "${temp}"

docker run --rm  \
       -v "${HOME}/dotfiles/private/API/:/var/GT:" \
       -v "${HOME}/dotfiles/private/rss_translator:/DB" \
       -v "/tmp/RSS:/var/RSS" \
       s2e/rss_translator

rm "${temp}"
