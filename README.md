# ROS2 Humble Overlay

Fork if you need your own version.

## Important
Ensure you have the `ros2-module.nix` added to your config.
Do need to add as a separate module, but you need the options and settings stated in the file.

## Commands to develop:

`nix develop` - To install necessary dependencies.

**/src** will be your main folder with packages.

```
cd /src
ros2 pkg create --build-type ament_cmake --node-name my_node my_package
cd ..
```
Run this command to build a package with a node template.

`colcon build --symlink-install` - build the c++ package with colcon.

## Running the node
```
source install/setup.bash
ros2 run my_package my_node
```