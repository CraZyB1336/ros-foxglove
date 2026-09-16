{ self, isHomeManager ? false}:
{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkOption mkIf mkMerge types literalExpression optional;

  system = pkgs.stdenv.hostPlatform.system;
  ownPkgs = self.legacyPackages.${system};

  fox = config.programs.foxglove-studio;
  ros = config.programs.ros2;

  rosSet = ownPkgs.rosPackages.${ros.distro};

  rosEnv = rosSet.buildEnv {
    paths = ros.packages rosSet
      ++ optional ros.foxgloveBridge rosSet.foxglove-bridge;
  };

  installTo = pkgList:
    if isHomeManager
    then { home.packages = pkgList; }
    else { environment.systemPackages = pkgList; };
in
{
  options.programs = {
    foxglove-studio = {
      enable = mkEnableOption "Foxglove Studio";
      package = mkOption {
        type = types.package;
        default = self.package.${system}.foxglove-studio;
        defaultText = literalExpression "ros-foxglove.packages.\${system}.foxglove-studio";
      };
    };

    ros2 = {
      enable = mkEnableOption "ROS 2 (via nix-ros-overlay)";

      distro = mkOption {
        type = types.str;
        default = "humble";
        example = "jazzy";
        description = "ROS 2 distribution from nix-ros-overlay";
      };

      packages = mkOption {
        type = types.functionTo (types.listOf types.package);
        default = p: [  ];
        example = literalExp.ros-core p.rviz2 p.demo-nodes-cpp p.ament-cmake-core p.python-cmake-modulepression "p: [ p.ros-core p.rviz2 p.demo-nodes-cpp p.ament-cmake-core p.python-cmake-module ]";
        description = "ROS packages to install";
      };

      foxgloveBridge = mkOption {
        type = types.bool;
        default = fox.enable;
        description = "Install foxglove_bridge so Foxglove can connect to live topics";
      };

      colcon = mkOption {
        type = types.bool;
        default = true;
        description = "Install colcon";
      };
    } // lib.optionalAttrs (!isHomeManager) {
      useBinaryCache = mkOption {
        type = types.bool;
        default = true;
        description = "Add ros.cachix.org as a substituter";
      };
    };
  };

  config = mkMerge [
    (mkIf fox.enable (installTo [ fox.package ]))
    (mkIf ros.enable (installTo ([ rosEnv ] ++ optional ros.colcon ownPkgs.colcon)))
    (lib.optionalAttrs (!isHomeManager) (mkIf (ros.enable && ros.useBinaryCache) {
      nix.settings = {
        substituters = [ "https://ros.cachix.org" ];
        trusted-public-keys = [
          "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo="
        ];
      };
    }))
  ];
}