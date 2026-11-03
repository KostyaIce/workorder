#include "TokenCipher.h"

#include <QCryptographicHash>
#include <QMessageAuthenticationCode>
#include <QRandomGenerator>

namespace workorder
{

namespace
{

const char *kPrefix = "enc:v1:";
constexpr int kPrefixSize = sizeof("enc:v1:") - 1;
const char *kKeyHex =
    "7c0056dd2011b34707ba6aaee9262d38cdbf97c98f5b0634f959a4eb3729db5f";
constexpr int kNonceSize = 16;
constexpr int kMacSize = 32;
constexpr int kBlockSize = 32;

QByteArray secretKey()
{
    return QByteArray::fromHex(QByteArray(kKeyHex));
}

QByteArray makeNonce()
{
    QByteArray nonce(kNonceSize, Qt::Uninitialized);
    for(int i = 0; i < nonce.size(); ++i)
        nonce[i] = static_cast<char>(QRandomGenerator::system()->bounded(256));
    return nonce;
}

QByteArray keystream(const QByteArray &key, const QByteArray &nonce, int length)
{
    QByteArray stream;
    stream.reserve(length);

    quint64 counter = 0;
    while(stream.size() < length)
    {
        QByteArray counterBytes(8, 0);
        for(int i = 0; i < 8; ++i)
            counterBytes[7 - i] = static_cast<char>((counter >> (i * 8)) & 0xff);

        stream.append(QCryptographicHash::hash(
            key + nonce + counterBytes, QCryptographicHash::Sha256));
        ++counter;
    }

    stream.truncate(length);
    return stream;
}

QByteArray xorBytes(const QByteArray &data, const QByteArray &stream)
{
    QByteArray result = data;
    for(int i = 0; i < result.size(); ++i)
        result[i] = static_cast<char>(result[i] ^ stream[i]);
    return result;
}

bool constantTimeEquals(const QByteArray &left, const QByteArray &right)
{
    if(left.size() != right.size())
        return false;

    unsigned char difference = 0;
    for(int i = 0; i < left.size(); ++i)
        difference |= static_cast<unsigned char>(left[i] ^ right[i]);
    return difference == 0;
}

} // namespace

bool TokenCipher::isEncrypted(const QString &storedValue)
{
    return storedValue.startsWith(QLatin1String(kPrefix));
}

QString TokenCipher::encrypt(const QString &plaintext)
{
    if(plaintext.isEmpty())
        return {};

    const QByteArray key = secretKey();
    const QByteArray nonce = makeNonce();
    const QByteArray data = plaintext.toUtf8();
    const QByteArray ciphertext = xorBytes(data, keystream(key, nonce, data.size()));
    const QByteArray mac = QMessageAuthenticationCode::hash(
        nonce + ciphertext, key, QCryptographicHash::Sha256);

    return QString::fromLatin1(kPrefix)
        + QString::fromLatin1((nonce + ciphertext + mac).toBase64());
}

QString TokenCipher::decrypt(const QString &storedValue)
{
    if(!isEncrypted(storedValue))
        return {};

    const QByteArray payload = QByteArray::fromBase64(
        storedValue.mid(kPrefixSize).toLatin1());
    if(payload.size() < kNonceSize + kMacSize)
        return {};

    const QByteArray key = secretKey();
    const QByteArray nonce = payload.left(kNonceSize);
    const QByteArray ciphertext = payload.mid(
        kNonceSize, payload.size() - kNonceSize - kMacSize);
    const QByteArray mac = payload.right(kMacSize);
    const QByteArray expectedMac = QMessageAuthenticationCode::hash(
        nonce + ciphertext, key, QCryptographicHash::Sha256);

    if(!constantTimeEquals(mac, expectedMac))
        return {};

    return QString::fromUtf8(
        xorBytes(ciphertext, keystream(key, nonce, ciphertext.size())));
}

} // namespace workorder
