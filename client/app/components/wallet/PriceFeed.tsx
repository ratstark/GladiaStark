"use client"
import { useAccount } from '@starknet-react/core'
import { useCallback, useEffect, useState } from 'react'
import { StoneButton } from '../StoneButton'

const PRAGMA_HELPER_CONTRACT = '0x005780114a5fab06357cdd54a78f45663e98fa1fe99a50083ab285826719212c'
const STRK_ASSET_ID = '6004514686061859652' // "ETH" in hex

export const PriceFeed = () => {
    const [tokenPerUsd, setTokenPerUsd] = useState<string>()
    const [assetPrice, setAssetPrice] = useState<string>()
    const [error, setError] = useState<string>()
    const { account } = useAccount()

    const fetchPrices = useCallback(async () => {
        if (!account) return
        try {
            // Fetch token per USD
            const tokenPerUsdResult = await account.callContract({
                contractAddress: PRAGMA_HELPER_CONTRACT,
                entrypoint: 'get_token_per_usd',
                calldata: [STRK_ASSET_ID],
            })
            setTokenPerUsd(tokenPerUsdResult[0])

            // Fetch asset price
            const assetPriceResult = await account.callContract({
                contractAddress: PRAGMA_HELPER_CONTRACT,
                entrypoint: 'get_asset_price',
                calldata: [STRK_ASSET_ID],
            })
            setAssetPrice(assetPriceResult[0])
            
            setError(undefined)
        } catch (e) {
            console.error('Failed to fetch prices:', e)
            setError('Failed to fetch prices')
        }
    }, [account])

    useEffect(() => {
        fetchPrices()
        // Refresh prices every 30 seconds
        const interval = setInterval(fetchPrices, 30000)
        return () => clearInterval(interval)
    }, [fetchPrices])

    if (!account) return null

    return (
        <div className="flex flex-col items-center gap-2">
            <StoneButton onClick={fetchPrices}>
                Refresh STRK
            </StoneButton>
            {tokenPerUsd && (
                <p className="text-white">
                    1 USD = {tokenPerUsd} STRK
                </p>
            )}
            {assetPrice && (
                <p className="text-white">
                    STRK Price: ${(Number(assetPrice) / 100000000).toFixed(2)}
                </p>
            )}
            {error && <p className="text-red-500">{error}</p>}
        </div>
    )
}
