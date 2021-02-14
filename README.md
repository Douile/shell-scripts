# Generic installers I use

## Order for new arch install
**Boot arch iso**
1. [luks-llvm](./luks-llvm)
**Reboot into new system**
2. [doas](./doas)
  - As root
  - Afterwards create user in "sudo" group
3. [paru](./paru)
4. [lightdm](./lightdm)
5. Any window manager
  - [qtile](./qtile)
  - [dwm (broken)](./dwm)
