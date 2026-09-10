{ pkgs, ... }:
{
  nix.settings = {
    # Needed for nix develop
    experimental-features = [ "nix-command" "flakes" ];

    # ROS binary cache
    extra-substituters = [ "https://ros.cachix.org" ];
    extra-trusted-public-keys = [
      "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo="
    ];
  };

  hardware.graphics.enable = true;
  environment.systemPackages = [ pkgs.git ];
}