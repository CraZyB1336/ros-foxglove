# ros-foxglove
Nix flake that installs ROS 2 (from **[nix-ros-overlay](https://github.com/lopsided98/nix-ros-overlay))** and **[Foxglove Studio](https://foxglove.dev/)** on Nix and NixOS.

## Summary
The ros-foxglove flake adds:
- A dev shell for building ROS workspaces.
- A runnable package `nix run`.
- A NixOS module and a Home Manager module: \
    `programs.ros2.enable`, `programs.foxglove-studio.enable`.

The supported systems are **x86_64-linux**, and **aarch64-linux**.

### Why?
Foxglove Studio is only distributed as a `.deb` package. Thus the flake downloads a specific version and unpakcs it and runs the **Electron** binary inside a `buildFHSEnv`, which gives it the standard Linux filesystem layout and libraries that it expects. A desktop file is also included.

ROS 2 comes from the [nix-ros-overlay](https://github.com/lopsided98/nix-ros-overlay), using its specific version nixpkgs. The modules uses your own flake's package set such that we can cache the built nixpkgs. This skips the initial building process which might take hours.

## Options
| Option | Default | Description |
|---|---|---|
| `programs.foxglove-studio.enable` | `false` | Installs Foxglove Studio. |
| `programs.foxglove-studio.package` | this flake's build | Override the Foxglove package. |
| `programs.ros2.enable` | `false` | Installs ROS 2. |
| `programs.ros2.distro` | `"humble"` | Distro name as used in nix-ros-overlay ('humble', 'jazzy', ...). |
| `programs.ros2.packages` | `p.ros-core p.rviz2 p.demo-nodes-cpp p.ament-cmake-core p.python-cmake-module` | Functions selecting ROS packages from the distro's set. |
| `programs.ros2.foxgloveBridge` | same as Foxglove `enable` | Install `foxglove_bridge`. |
| `programs.ros2.colcon` | `true` | Installs colcon. |
| `programs.ros2.useBinaryCache` | `true` | *(NixOS only)* Add `ros.cachix.org` as a substituter. |

## Quick start
Running Foxglove without installing anything:
```sh
nix run github:CraZyB1336/ros-foxglove
```

Installing it into your user profile:
```sh
nix profile install github:CraZyB1336/ros-foxglove
```

Entering the ROS2 Humble dev shell (ROS, colcon, foxglove_bridge, Foxglove):
```sh
nix run github:CraZyB1336/ros-foxglove
```

## NixOS Module
Add the flake as an input and import the module:

### Minimal Flake example
#### Flake.nix
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ros-foxglove.url = "github:YOURNAME/ros-foxglove";
    # Do NOT add ros-foxglove.inputs.nixpkgs.follows, or the ROS binary cache stops matching.
  };

  outputs = { nixpkgs, ros-foxglove, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix # Or whatever your default module is
        ros-foxglove.nixosModules.default
      ];
    };
  };
}
```

#### configuration.nix
```nix
{ config, pkgs, ... }:
{
  programs.foxglove-studio.enable = true;
  programs.ros2 = {
    enable = true;
    distro = "humble";
    packages = p: [ p.ros-core p.rviz2 p.demo-nodes-cpp p.ament-cmake-core p.python-cmake-module ];
  };
}
```

### Inline Flake example
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ros-foxglove.url = "github:YOURNAME/ros-foxglove";
    # Do NOT add ros-foxglove.inputs.nixpkgs.follows, or the ROS binary cache stops matching.
  };

  outputs = { nixpkgs, ros-foxglove, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix # Or whatever your default module is
        ros-foxglove.nixosModules.default
        {
          programs.foxglove-studio.enable = true;

          programs.ros2 = {
            enable = true;
            distro = "humble";
            packages = p: [ p.ros-core p.rviz2 p.demo-nodes-cpp p.ament-cmake-core p.python-cmake-module ];
          };
        }
      ];
    };
  };
}
```

## Home Manager Module
```nix
{ inputs, ... }:
{
  imports = [ inputs.ros-foxglove.homeManagerModules.default ];

  programs.foxglove-studio.enable = true;
  programs.ros2.enable = true;
}
```
As with NixOS Module you can import the module in `flake.nix` and keep the options in your `home.nix`.

Home Manager cannot change system Nix settings, so add the ROS cache yourself in `/etc/nix/nix.conf` (or `nix.settings` on NixOS):
```nix
extra-substituters = https://ros.cachix.org
extra-trusted-public-keys = ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=
```

## Connecting Foxglove to ROS 2
```sh
ros2 launch foxglove_bridge foxglove_bridge_launch.xml
```
In Foxglove, choose **Open connection -> Foxglove WebSocket** and use `ws://localhost:8765`.

## System install vs dev shell
- **System install (modules):** good for running things such as `ros2 topic list`, `ros2 run`, `ros2 launch`, RViz, and Foxglove.
- **Dev shell** (`nix develop`)**:** use this for building your own colcon workspaces. It sets the CMake and Python paths that a regular login shell doesn't have. The shell automatically sources `install/setup.bash` if it exists.