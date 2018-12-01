### Illustrate
- This project aims to deploy shadowsocks from source on your `VPS` by just single command
    - just to save my time when tranfserred between different `VPS`
    - dynamic generate executable file for /etc/init.d/ use
- Why choose `c` version of source
    - support udp relay
    - work faster
- Why choose CentOS
    - personal hobby
    - good reputation for running as server
- code also for Ubuntu, though not checked yet

Current released version v1.0

### Quick Start
```bash
> sh oneKey.sh
[NAME]
    oneKey.sh -- deploy shadowsocks on you VPS from c source

[SYNOPSIS]
    sh oneKey.sh [home | root | help]

[EXAMPLE]
    sh oneKey.sh
    sh oneKey.sh root

[NOTE]
    both modes need root privilege, but no sudo prefix

[DESCRIPTION]
    home -- install to ~/.usr/
    root -- install to /usr/local/
             _       _       _
 _   _ _ __ | | __ _| |_ ___| |__
| | | | '_ \| |/ _` | __/ __| '_ \
| |_| | | | | | (_| | || (__| | | |
 \__,_|_| |_|_|\__,_|\__\___|_| |_|

```

```bash
sh oneKey.sh root
```

### License
The [MIT](https://github.com/xiangp126/let-ss/blob/master/LICENSE.txt) License(MIT)
