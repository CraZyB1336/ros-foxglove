{
  description = "ROS2 and Foxglove Studio. Packages, dev shell, NixOS and Home Manager modules";

  inputs = {
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";
    nixpkgs.follows = "nix-ros-overlay/nixpkgs";
  };

  outputs = { self, nix-ros-overlay, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];

      pkgsFor = system: import nixpkgs {
        inherit system;
        overlays = [ nix-ros-overlay.overlays.default self.overlays.default ];
        config.allowUnfreePredicate = pkg: (nixpkgs.lib.getName pkg) == "foxglove-studio";
      };
    in
    {
      overlays.default = final: prev: {
        foxglove-studio = final.callPackage ./pkgs/foxglove-studio.nix { };
      };

      nixosModules.default = import ./modules { inherit self; };
      homeManagerModules.default = import ./modules { inherit self; isHomeManager = true; };     
    }
    // nix-ros-overlay.inputs.flake-utils.lib.eachSystem systems (system:
      let pkgs = pkgsFor system; in
      {
        legacyPackages = pkgs;

        packages = {
          foxglove-studio = pkgs.foxglove-studio;
          default = pkgs.foxglove-studio;
        };
        
        apps.default = {
          type = "app";
          program = "${pkgs.foxglove-studio}/bin/foxglove-studio";
        };

        devShells.default = pkgs.mkShell {
          name = "ros2-humble";
          packages = [
            pkgs.colcon
            pkgs.foxglove-studio
            (with pkgs.rosPackages.humble; buildEnv {
              underlay = true;
              paths = [ 
                ros-core
                ament-cmake-core
                python-cmake-module
                demo-nodes-cpp
                foxglove-bridge
                vision-msgs
                cv-bridge
              ];
            })
          ];

          buildInputs = [
            pkgs.pcl
            pkgs.eigen
            pkgs.boost
            pkgs.flann
          ];
          shellHook = ''
            [ -f install/setup.bash ] && source install/setup.bash
          '';
        };
      });
  
  nixConfig = {
    extra-substituters = [ "https://ros.cachix.org" ];
    extra-trusted-public-keys = [
      "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo="
    ];
  };
}