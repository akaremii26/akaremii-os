#!/usr/bin/env bash
set -euo pipefail

readonly KWIN_COMMIT="ab7df7ccb7c6af20f4b279cd6220f7cd3d2267d7"
readonly PLASMA_WAYLAND_PROTOCOLS_COMMIT="de088ef1c6115d9a4c8eab3dd00516959586721f"
readonly WAYLAND_COMMIT="5f430e41167dd359b70fb5e9f584ba2dc058e4cc"
readonly KNIGHTTIME_COMMIT="3145e781c5d2bdc414d66491e5537a3b27b2898f"
readonly KDECORE_COMMIT="061e3a73146fc986253476a4e1c1711a2a685fcf"
readonly KWAYLAND_COMMIT="4273bbb101bd08ffdba33c24d2fad68b8db7566e"
readonly KGLOBALACCELD_COMMIT="e9517633f81211c236ad09fbcc5854ea8174c3e5"

readonly WORKDIR="/tmp/kwin-build"
readonly PREFIX_ROOT="/out"
readonly SOURCE_ROOT="${WORKDIR}/sources"
readonly BUILD_ROOT="${WORKDIR}/builds"

export CMAKE_PREFIX_PATH="${PREFIX_ROOT}/usr:/usr"
export PKG_CONFIG_PATH="${PREFIX_ROOT}/usr/lib64/pkgconfig:${PREFIX_ROOT}/usr/lib/pkgconfig:/usr/lib64/pkgconfig"
export PATH="${PREFIX_ROOT}/usr/bin:/usr/bin:${PATH}"

rm -rf "${WORKDIR}" "${PREFIX_ROOT}"
mkdir -p "${SOURCE_ROOT}" "${BUILD_ROOT}" "${PREFIX_ROOT}"

fetch_repo() {
    local name="$1"
    local url="$2"
    local commit="$3"
    local destination="${SOURCE_ROOT}/${name}"

    git init --quiet "${destination}"
    git -C "${destination}" remote add origin "${url}"
    git -C "${destination}" fetch --quiet --depth=1 origin "${commit}"
    git -C "${destination}" checkout --quiet --detach FETCH_HEAD
}

cmake_install_project() {
    local name="$1"
    local source="${SOURCE_ROOT}/${name}"
    local build="${BUILD_ROOT}/${name}"
    local -a cmake_options=(
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=/usr
        -DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}"
        -DBUILD_TESTING=OFF
    )

    if [[ "${name}" == kwin ]]; then
        cmake_options+=(
            -DKWIN_BUILD_ACTIVITIES=ON
            -DCMAKE_INSTALL_LIBEXECDIR=libexec
            -DKDE_INSTALL_LIBEXECDIR=libexec
        )
    fi

    cmake -S "${source}" -B "${build}" -G Ninja \
        "${cmake_options[@]}"
    cmake --build "${build}" --parallel "$(nproc)"
    DESTDIR="${PREFIX_ROOT}" cmake --install "${build}"
}

fetch_repo plasma-wayland-protocols \
    https://invent.kde.org/libraries/plasma-wayland-protocols.git \
    "${PLASMA_WAYLAND_PROTOCOLS_COMMIT}"
cmake_install_project plasma-wayland-protocols

fetch_repo wayland \
    https://gitlab.freedesktop.org/wayland/wayland.git \
    "${WAYLAND_COMMIT}"
meson setup "${BUILD_ROOT}/wayland" "${SOURCE_ROOT}/wayland" \
    --buildtype=release \
    --prefix=/usr \
    --libdir=lib64 \
    -Ddocumentation=false \
    -Dtests=false
meson compile -C "${BUILD_ROOT}/wayland"
DESTDIR="${PREFIX_ROOT}" meson install -C "${BUILD_ROOT}/wayland"

fetch_repo knighttime \
    https://invent.kde.org/plasma/knighttime.git \
    "${KNIGHTTIME_COMMIT}"
cmake_install_project knighttime

fetch_repo kdecoration \
    https://invent.kde.org/plasma/kdecoration.git \
    "${KDECORE_COMMIT}"
cmake_install_project kdecoration

fetch_repo kwayland \
    https://invent.kde.org/plasma/kwayland.git \
    "${KWAYLAND_COMMIT}"
cmake_install_project kwayland

fetch_repo kglobalacceld \
    https://invent.kde.org/plasma/kglobalacceld.git \
    "${KGLOBALACCELD_COMMIT}"
cmake_install_project kglobalacceld

fetch_repo kwin \
    https://invent.kde.org/plasma/kwin.git \
    "${KWIN_COMMIT}"
git -C "${SOURCE_ROOT}/kwin" apply --check /tmp/discrete-swipes.patch
git -C "${SOURCE_ROOT}/kwin" apply /tmp/discrete-swipes.patch
cmake_install_project kwin

rm -rf "${WORKDIR}"
