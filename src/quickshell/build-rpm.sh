#!/usr/bin/env bash
# Builds the Quickshell RPM inside a container from the pinned Fedora image.
# Called by `task quickshell:rpm`; never run on the host.
#
# The source is a shallow clone of the pinned tag, refused unless it resolves to
# the pinned commit, so a moved tag cannot change what we build. Qt and the other
# build dependencies come from the spec's BuildRequires; their installed versions
# are passed to rpmbuild so the package requires exactly that Qt.
#
# Mounts: /src/quickshell (this folder, read-only), /out (output/rpms), /ccache (compiler cache).
# Environment: QS_GIT, QS_TAG, QS_COMMIT, QS_KEY, from versions.yml and the task.
set -euo pipefail

: "${QS_GIT:?}" "${QS_TAG:?}" "${QS_COMMIT:?}" "${QS_KEY:?}"

spec=/src/quickshell/quickshell.spec
top=$(mktemp -d)
mkdir -p "$top/SOURCES"

# Fedora's updates-archive keeps every update that reached stable, so Qt
# versions the image pins stay installable after `updates` moves on. Its repo
# file comes from fedora-repos-archive, which the toolbox image lacks.
dnf install -y fedora-repos-archive
dnf_opts=(-y --setopt=install_weak_deps=False --enablerepo=updates-archive)

echo "Fetching Quickshell $QS_TAG"
dnf install "${dnf_opts[@]}" git-core rpm-build dnf-plugins-core
src=$(mktemp -d)
git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$QS_TAG" "$QS_GIT" "$src"
actual=$(git -C "$src" rev-parse HEAD)
if [[ $actual != "$QS_COMMIT" ]]; then
  echo "Tag $QS_TAG is $actual, versions.yml pins $QS_COMMIT; refusing to build." >&2
  exit 1
fi
short=${QS_COMMIT:0:7}
git -C "$src" archive --prefix="quickshell-$short/" -o "$top/SOURCES/quickshell-$short.tar.gz" HEAD

# The version comes from upstream's CMakeLists.txt, so the RPM name matches the tag.
version=$(sed -n 's/^project(quickshell VERSION "\([^"]*\)".*/\1/p' "$src/CMakeLists.txt")
: "${version:?could not read the version from CMakeLists.txt}"

defines=(
  --define "_topdir $top"
  --define "qs_version $version"
  --define "qs_commit $QS_COMMIT"
)

echo "Installing build dependencies"
dnf builddep "${dnf_opts[@]}" "${defines[@]}" "$spec"

defines+=(
  --define "qt6_base_evr $(rpm -q --qf '%{EPOCH}:%{VERSION}-%{RELEASE}' qt6-qtbase | sed 's/^(none)://')"
  --define "qt6_declarative_evr $(rpm -q --qf '%{EPOCH}:%{VERSION}-%{RELEASE}' qt6-qtdeclarative | sed 's/^(none)://')"
)

echo "Building against $(rpm -q qt6-qtbase qt6-qtdeclarative | tr '\n' ' ')"
# _topdir is a fresh temp dir each run; tell ccache to ignore it so hits survive.
export CCACHE_DIR=/ccache CCACHE_BASEDIR=$top CCACHE_NOHASHDIR=1
rpmbuild -bb "${defines[@]}" "$spec"

mapfile -t rpms < <(find "$top/RPMS" -name "quickshell-$version-*.x86_64.rpm" -not -name '*debug*')
if ((${#rpms[@]} != 1)); then
  echo "Expected one quickshell RPM, found ${#rpms[@]}: ${rpms[*]}" >&2
  exit 1
fi
# Copy then rename, so an interrupted copy never looks like a finished build.
cp "${rpms[0]}" "/out/.quickshell-$QS_KEY.rpm.tmp"
mv "/out/.quickshell-$QS_KEY.rpm.tmp" "/out/quickshell-$QS_KEY.rpm"
echo "Wrote output/rpms/quickshell-$QS_KEY.rpm"
ccache --show-stats --verbose | sed -n 's/^ *\(Hits\|Misses\):/ccache &/p' || true
