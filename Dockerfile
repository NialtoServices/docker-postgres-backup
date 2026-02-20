# syntax=docker/dockerfile:1
#
# Copyright 2026 Nialto Services Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ARG ALPINE_VERSION=3.23

FROM alpine:${ALPINE_VERSION}

LABEL org.opencontainers.image.description="Scheduled PostgreSQL backups with rclone"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.source="https://github.com/NialtoServices/docker-postgres-backup"

ARG POSTGRES_MAJOR=18

RUN apk upgrade --no-cache
RUN apk add --no-cache curl postgresql${POSTGRES_MAJOR}-client rclone tini util-linux

COPY ./bin/backup /usr/local/bin/backup
COPY ./bin/notify-failure /usr/local/bin/notify-failure
COPY ./bin/start /usr/local/bin/start

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["/usr/local/bin/start"]
