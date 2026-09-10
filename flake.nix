{
  description = "ROS2 Humble dev env";

  inputs = {
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";
    nixpkgs.follows = "nix-ros-overlay/nixpkgs";
  };

  outputs = { self, nix-ros-overlay, nixpkgs }:
    nix-ros-overlay.inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ nix-ros-overlay.overlays.default ];
        };
      in {
        devShells.default = pkgs.mkShell {
          name = "ros2-humble";
          packages = [
            # Non-ROS tooling
            pkgs.colcon

            # ROS2 Humble pkgs
            (with pkgs.rosPackages.humble; buildEnv {
              underlay = true;
              paths = [
                ros-core        # rclcpp, rclpy, ament_cmake, ros2 CLI, launch
                ament-cmake-core
                python-cmake-module
                demo-nodes-cpp  # testing: ros2 run demo_nodes_cpp talker
                #rviz2          # I think it is a graphical interface
                #desktop        # desktop metapackage (biiiig, large)
                #... add more package.xml dependencies here.
              ];
            })
          ];

          shellHook = ''
            if [ -f install/setup.bash ]; then
              source install/setup.bash
            fi
          '';
        };
      }
    );

  nixConfig = {
    extra-substituters = [ "https://ros.cachix.org" ];
    extra-trusted-public-keys = [
      "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo="
    ];
  };
}