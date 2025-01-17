"use client"
import { useAccount, useExplorer } from '@starknet-react/core'
import { useCallback, useState } from 'react'
import { Button } from '@chakra-ui/react'

const ETH_CONTRACT =
    '0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7'

export const TransferEth = () => {
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
                        contractAddress: ETH_CONTRACT,
                        entrypoint: 'approve',
                        calldata: [account?.address, amount, '0x0'],
                    },
                    {
                        contractAddress: ETH_CONTRACT,
                        entrypoint: 'transfer',
                        calldata: [account?.address, amount, '0x0'],
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
        <div className="transfer-container">
            <Button onClick={() => execute('0x1C6BF52634000')} disabled={submitted}>
                Transfer 0.005 ETH
            </Button>
            {txnHash && (
                <div className="transaction-info">
                    Transaction hash:
                    <a
                        href={explorer.transaction(txnHash)}
                        target="_blank"
                        rel="noreferrer"
                    >
                        {txnHash}
                    </a>
                </div>
            )}
        </div>
    )
}