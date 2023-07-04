/// Support of wallets (v3, v3r2, v4r2)
library wallet;

export 'src/wallet/api.dart'
    show
        WalletContractV3R1,
        WalletContractV3R2,
        WalletContractV4R2,
        createWalletTransferV3,
        createWalletTransferV4;
