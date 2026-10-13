#!/usr/bin/env bash
#
# 构建 apollo-adminservice 并推送镜像
# 用法: ./build-adminservice.sh                  # VERSION=2.1.0, TAG=2.1.0-debian12
#       VERSION=2.5.2 ./build-adminservice.sh    # TAG=2.5.2-debian12
#
set -euo pipefail

COMPONENT="adminservice"

REGISTRY="${REGISTRY:-zetta-docker-repository-registry.cn-beijing.cr.aliyuncs.com/zetta-studio}"
IMAGE_NAME="${IMAGE_NAME:-apollo-${COMPONENT}}"
# VERSION 为 maven 构建版本（通过 -Drevision 传入），TAG 在其后追加基础系统后缀
VERSION="${VERSION:-2.1.0}"
TAG="${TAG:-${VERSION}-debian12}"

# docker file名称，名称可指定，默认为“Dockerfile”
DOCKERFILE="${DOCKERFILE:-Dockerfile}"
# ---- 指定平台架构，支持 "linux/amd64"、 "linux/arm64"、"linux/amd64,linux/arm64"(混合架构) 三种，当前默认为 amd64
platforms="${PLATFORMS:-linux/amd64}"

# 额外的 maven 参数，例如 MVN_ARGS="-Dapollo_profile=github"
MVN_ARGS="${MVN_ARGS:-}"

docker_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../apollo-adminservice/src/main/docker
module_dir="$(cd "${docker_dir}/../../.." && pwd)"           # .../apollo-adminservice
project_root="$(dirname "$module_dir")"                      # .../apollo
module="apollo-${COMPONENT}"

# 1. maven 打包（在根目录执行，-am 同时构建依赖模块）
echo "==> mvn clean package -DskipTests -pl ${module} -am -Drevision=${VERSION}"
(cd "${project_root}" && mvn clean package -DskipTests -pl "${module}" -am -Drevision="${VERSION}" ${MVN_ARGS})

# 2. copy 产物到 docker 目录
zip_name="${module}-${VERSION}-github.zip"
zip_file="${module_dir}/target/${zip_name}"
if [ ! -f "${zip_file}" ]; then
  echo "${zip_file} does not exist"
  exit 1
fi

# 清理 docker 目录下旧版本的 zip，避免进入构建上下文
rm -f "${docker_dir}"/${module}-*-github.zip
cp "${zip_file}" "${docker_dir}/"
echo "==> copied ${zip_name} to ${docker_dir}"

# 3. 构建并推送镜像
image="${REGISTRY}/${IMAGE_NAME}:${TAG}"
echo "==> building ${image} (platforms: ${platforms})"
docker buildx build \
    --platform "${platforms}" \
    --file "${docker_dir}/${DOCKERFILE}" \
    --build-arg "VERSION=${VERSION}" \
    --tag "${image}" \
    --push \
    "${docker_dir}"

echo "==> pushed ${image}"
