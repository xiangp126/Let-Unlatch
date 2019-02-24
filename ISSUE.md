## Issue

### mbed TLS not found
- phenomenon

```
configure: error: mbed TLS libraries not found.
make: *** No targets specified and no makefile found.  Stop.
```

- solution

```bash
wget https://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/m/mbedtls-devel-2.7.9-1.el7.x86_64.rpm
sudo yum install mbedtls-devel-2.7.9-1.el7.x86_64.rpm
```

or

```bash
sudo yum install packages/mbedtls-devel-2.7.9-1.el7.x86_64.rpm
```