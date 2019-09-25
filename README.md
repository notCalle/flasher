# flasher

Write images to removable media, asking for authorization if needed.

See the [changelog] for recent changes.

[changelog]: CHANGELOG.md

## Usage

### List safe (external, removable) devices

```shell
> flasher list
disk6 "DataTraveler G2" (16,06 GB)
```

### Write an image to a device

```shell
> flasher write disk6 ~/Downloads/example-DVD.iso
```


## Building

### Package

This builds an installer package that installs flasher in `/usr/local/bin`.

```shell
> make pkg
```
