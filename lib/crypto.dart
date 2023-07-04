/// Underlying crypto primitives
library crypto;

/// CRC16 (including CRC16 over method ids table, CRC32c
export 'src/crypto/crc/api.dart' show Crc16, Crc32c;

/// Signing and verifying primitives using Ed25519
export 'src/crypto/nacl/api.dart'
    show KeyPair, sign, signVerify, sealBox, openBox;

/// Utilities and higher-level wrappers
export 'src/crypto/utils/api.dart' show safeSign, safeSignVerify;
