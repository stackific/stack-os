# Quickshell, built from a pinned upstream tag for Stack OS (decision 05).
# Adapted from Fedora's quickshell spec (src.fedoraproject.org/rpms/quickshell).
#
# Quickshell links Qt's private APIs, so it must run with exactly the Qt it was
# compiled against. build-rpm.sh passes the installed Qt versions in as
# qt6_base_evr and qt6_declarative_evr, and this package requires them exactly;
# dnf then refuses or pulls the matching Qt instead of crashing at runtime.
#
# Stack OS runs on Mango under Wayland only, so X11 and the Hyprland and i3
# integrations are off. The crash handler is off because it needs cpptrace,
# which Fedora does not package; systemd restarts the shell instead.
#
# Inputs: qs_commit (the pinned commit; build-rpm.sh has already checked that
# the tag points at it) and Source0, a `git archive` of that commit.

%global qs_shortcommit %{sub %{qs_commit} 1 7}

Name:           quickshell
Version:        %{qs_version}
Release:        1.stackos%{?dist}
Summary:        QtQuick toolkit for desktop shells (Stack OS build)
# The code is LGPL; the bundled Wayland protocol files are BSD-3-Clause and
# HPND-sell-variant.
License:        LGPL-3.0-or-later AND BSD-3-Clause AND HPND-sell-variant
URL:            https://quickshell.org/
Source0:        quickshell-%{qs_shortcommit}.tar.gz

BuildRequires:  cmake
BuildRequires:  ninja-build
BuildRequires:  gcc-c++
BuildRequires:  ccache
BuildRequires:  desktop-file-utils
BuildRequires:  spirv-tools
BuildRequires:  cmake(Qt6Core)
BuildRequires:  cmake(Qt6CorePrivate)
BuildRequires:  cmake(Qt6Qml)
BuildRequires:  cmake(Qt6QuickPrivate)
BuildRequires:  cmake(Qt6ShaderTools)
BuildRequires:  cmake(Qt6WaylandClient)
BuildRequires:  cmake(Qt6WaylandClientPrivate)
BuildRequires:  cmake(Qt6DBus)
BuildRequires:  cmake(Qt6Network)
BuildRequires:  cmake(CLI11)
BuildRequires:  cmake(VulkanHeaders)
BuildRequires:  pkgconfig(egl)
BuildRequires:  pkgconfig(gbm)
BuildRequires:  pkgconfig(glib-2.0)
BuildRequires:  pkgconfig(gobject-2.0)
BuildRequires:  pkgconfig(jemalloc)
BuildRequires:  pkgconfig(libdrm)
BuildRequires:  pkgconfig(libpipewire-0.3)
BuildRequires:  pkgconfig(pam)
BuildRequires:  pkgconfig(polkit-agent-1)
BuildRequires:  pkgconfig(polkit-gobject-1)
BuildRequires:  pkgconfig(wayland-client)
BuildRequires:  pkgconfig(wayland-protocols)
BuildRequires:  wayland-devel

# The exact Qt this build was compiled against (see the header).
%{?qt6_base_evr:Requires: qt6-qtbase%{?_isa} = %{qt6_base_evr}}
%{?qt6_declarative_evr:Requires: qt6-qtdeclarative%{?_isa} = %{qt6_declarative_evr}}
# Loaded at runtime, so rpm cannot detect them: SVG images and icons.
Requires:       qt6-qtsvg%{?_isa}

%description
Quickshell is a toolkit for building bars, widgets, lock screens and other
desktop shell components with QtQuick. This build is pinned to one upstream
commit and to the Qt it was compiled against, for Stack OS.

%prep
%autosetup -n quickshell-%{qs_shortcommit}

%conf
%cmake -GNinja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_SKIP_INSTALL_RPATH=ON \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
  -DDISTRIBUTOR="Stack OS" \
  -DINSTALL_QML_PREFIX=%{_lib}/qt6/qml \
  -DGIT_REVISION=%{qs_commit} \
  -DCRASH_HANDLER=OFF \
  -DX11=OFF \
  -DHYPRLAND=OFF \
  -DI3=OFF

%build
%cmake_build

%install
%cmake_install

%check
desktop-file-validate %{buildroot}%{_datadir}/applications/*.desktop

%files
%license LICENSE*
%doc README.md BUILD.md changelog/
%{_bindir}/qs
%{_bindir}/quickshell
%{_datadir}/applications/org.quickshell.desktop
%{_datadir}/icons/hicolor/scalable/apps/org.quickshell.svg
%{_libdir}/qt6/qml/Quickshell/
