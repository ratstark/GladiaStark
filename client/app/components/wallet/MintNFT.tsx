"use client"
import { useAccount, useExplorer } from '@starknet-react/core'
import { useCallback, useState } from 'react'
import { StoneButton } from '../StoneButton'

const MINT_CONTRACT =
    '0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7'

export const MintNFT = () => {
    const [submitted, setSubmitted] = useState<boolean>(false)
    const { account } = useAccount()
    const explorer = useExplorer()
    const [txnHash, setTxnHash] = useState<string>()

    const execute = useCallback(
        async (amount: string) => {
            if (!account) return
            setSubmitted(true)
            setTxnHash(undefined)
            try {
                const result = await account.execute([
                    {
                        contractAddress: MINT_CONTRACT,
                        entrypoint: 'approve',
                        calldata: [account?.address, amount],
                    },
                    {
                        contractAddress: MINT_CONTRACT,
                        entrypoint: 'mint',
                        calldata: [account?.address],
                    },
                ])
                setTxnHash(result.transaction_hash)
            } catch (e) {
                console.error(e)
            } finally {
                setSubmitted(false)
            }
        },
        [account],
    )

    if (!account) return null

    return (
        <div>
            <StoneButton onClick={() => execute('0x1C6BF52634000')} >
                Mint NFT
            </StoneButton>
            {txnHash && (
                <>
                    Transaction hash:{' '}
                    <a
                        href={explorer.transaction(txnHash)}
                        target="blank"
                        rel="noreferrer"
                    >
                        {txnHash}
                    </a>
                </>
            )}
        </div>
    )
}