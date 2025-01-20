'use client'

import React from 'react'
import { StoneButton } from '../components/StoneButton'
import { ConnectWallet } from '../components/wallet/ConnectWallet'
import { MintNFT } from '../components/wallet/MintNFT'
import { StarknetProvider } from '../components/wallet/StarknetProvider'
import { EnterArena } from '../components/wallet/EnterArena'
import { PriceFeed } from '../components/wallet/PriceFeed'

export default function Arena() {

    const handleStats = () => { };

    return (
        <StarknetProvider>
            <div className="page-container">
                <div className="top-right animate-fadeIn">
                    <ConnectWallet />
                </div>

                <div className="content-container animate-fadeIn">
                    <MintNFT />
                    <div className="flex flex-col gap-4">
                        <StoneButton onClick={handleStats}>
                            Stats
                        </StoneButton>
                        <EnterArena />
                        <PriceFeed />
                    </div>
                </div>
            </div>
        </StarknetProvider >
    )
}

