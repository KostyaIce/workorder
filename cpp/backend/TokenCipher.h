#ifndef WORKORDER_BACKEND_TOKEN_CIPHER_H
#define WORKORDER_BACKEND_TOKEN_CIPHER_H

#include <QString>

namespace workorder
{

// Lightweight authenticated encryption for locally stored tokens.
// The key is compiled into the app, so this protects against casual reading of
// the config file, not against reverse engineering.
class TokenCipher
{
public:
    static QString encrypt(const QString &plaintext);
    static QString decrypt(const QString &storedValue);
    static bool isEncrypted(const QString &storedValue);
};

} // namespace workorder

#endif // WORKORDER_BACKEND_TOKEN_CIPHER_H
