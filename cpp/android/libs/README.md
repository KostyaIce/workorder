# Android OpenSSL libraries

`arm64-v8a/libssl_3.so` and `arm64-v8a/libcrypto_3.so` are the OpenSSL 3
binaries from the KDAB `android_openssl` project:

- Source: https://github.com/KDAB/android_openssl
- License: Apache License 2.0, see `OPENSSL_LICENSE.txt`

Qt's Android OpenSSL TLS backend loads these files as `libssl_3.so` and
`libcrypto_3.so`.
