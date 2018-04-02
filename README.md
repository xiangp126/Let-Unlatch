- This project aims to deploy shadowsocks from source on your VPS by just single command
    - Just to save my time when tranfserred between different VPS
- Why choose c version of source
    - personal hobby
    - support udp relay
    - maybe faster

Current released version v1.0

## Quick Start
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
                _
 ___  ___   ___| | _____
/ __|/ _ \ / __| |/ / __|
\__ \ (_) | (__|   <\__ \
|___/\___/ \___|_|\_\___/
```

```bash
sh oneKey.sh install
```

## License
The [MIT]() License(MIT)
