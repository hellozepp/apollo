#
# Copyright 2022 Apollo Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Dockerfile for apollo-configservice
# 1. ./scripts/build.sh
# 2. Build with: mvn docker:build -pl apollo-configservice
# 3. Run with: docker run -p 8080:8080 -e SPRING_DATASOURCE_URL="jdbc:mysql://fill-in-the-correct-server:3306/ApolloConfigDB?characterEncoding=utf8" -e SPRING_DATASOURCE_USERNAME=FillInCorrectUser -e SPRING_DATASOURCE_PASSWORD=FillInCorrectPassword -d -v /tmp/logs:/opt/logs --name apollo-configservice apolloconfig/apollo-configservice

FROM zetta-docker-repository-registry.cn-beijing.cr.aliyuncs.com/zetta-studio/debian:12-slim AS app

ARG VERSION
ENV VERSION $VERSION

COPY apollo-configservice-${VERSION}-github.zip /apollo-configservice/apollo-configservice-${VERSION}-github.zip

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends unzip \
    && rm -rf /var/lib/apt/lists/* \
    && unzip /apollo-configservice/apollo-configservice-${VERSION}-github.zip -d /apollo-configservice \
    && rm -rf /apollo-configservice/apollo-configservice-${VERSION}-github.zip \
    && chmod +x /apollo-configservice/scripts/startup.sh

# 运行时基于 Debian 12 (bookworm)，JRE 取自 eclipse-temurin:17-jre
FROM debian:bookworm-slim
LABEL maintainer="g632104866@gmail.com;finchcn@gmail.com;ameizi<sxyx2008@163.com>"

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"
ENV LANG=C.UTF-8
ENV APOLLO_RUN_MODE="Docker"
ENV SERVER_PORT=8080

COPY --from=eclipse-temurin:17-jre /opt/java/openjdk /opt/java/openjdk

# perl-base/openssl/libssl3/libexpat1/libpcre2-8-0 有 CVE，install 会将已安装的包升级到 bookworm-security 中的最新版本
# 切换为阿里云源（含 debian-security）；用 http 是因为此时尚未安装 ca-certificates
RUN sed -i 's|deb.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends perl-base openssl libssl3 libexpat1 \
     libpcre2-8-0 ca-certificates procps curl bash tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

COPY --from=app /apollo-configservice /apollo-configservice

EXPOSE $SERVER_PORT

CMD ["/apollo-configservice/scripts/startup.sh"]