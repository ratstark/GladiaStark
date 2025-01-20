"use client"
import { useAccount, useExplorer, useTransactionReceipt } from '@starknet-react/core'
import { useCallback, useState, useEffect } from 'react'
import { StoneButton } from '../StoneButton'

const ARENA_CONTRACT = '0x03378dcd8e66d245468a57839d29c8a79347c76ea01afa19559ceab49b45fd6f'


export const EntranceFee = () => {
    const [submitted, setSubmitted] = useState<boolean>(false)
    const [showSuccess, setShowSuccess] = useState(false)
    const [error, setError] = useState<string>()
    const [price, setPrice] = useState<string>()
    const { account } = useAccount()
    const explorer = useExplorer()
    const [txnHash, setTxnHash] = useState<string>()



    const {
        data: receipt,
        isError,
        error: receiptError,
        isPending,
        isSuccess,
        status
    } = useTransactionReceipt({
        hash: txnHash,
        watch: true,
    })

    useEffect(() => {
        if (isSuccess) {
            setShowSuccess(true)
            const timer = setTimeout(() => setShowSuccess(false), 5000)
            return () => clearTimeout(timer)
        }
    }, [isSuccess, receipt])

    useEffect(() => {
        const fetchPrice = async () => {
            if (!account) return
            try {
                const result = await account.callContract({
                    contractAddress: ARENA_CONTRACT,
                    entrypoint: 'get_price_entry_eth',
                    calldata: [],
                })
                setPrice(result[0])
            } catch (e) {
                console.error('Failed to fetch price:', e)
            }
        }
        fetchPrice()
    }, [account])

    const execute = useCallback(
        async () => {
            if (!account) return
            setSubmitted(true)
            setError(undefined)
            setTxnHash(undefined)
            try {
                const result = await account.execute([
                    {
                        contractAddress: ARENA_CONTRACT,
                        entrypoint: 'entrance_payment',
                        calldata: [account?.address],
                    }
                ])
                if (!result?.transaction_hash) {
                    throw new Error("No transaction hash received")
                }
                setTxnHash(result.transaction_hash)
            } catch (e) {
                console.error(e)
                setError(e instanceof Error ? e.message : "Failed to pay entrance fee")
            } finally {
                setSubmitted(false)
            }
        },
        [account],
    )

    const buttonText = () => {
        if (submitted) return 'Processing Payment...'
        if (isPending && txnHash) return 'Processing...'
        return 'Pay Entrance Fee'
    }

    if (!account) return null

    return (
        <div>
            {price && <p className="text-white mb-2">Entrance Fee: {price} ETH</p>}
            <StoneButton
                onClick={() => execute()}

            >   {buttonText()}
            </StoneButton>
            {error && <p className="text-red-500">{error}</p>}
            {showSuccess && (
                <p className="text-green-500">Entrance fee paid successfully!</p>
            )}
            {(isError || receiptError) && (
                <p className="text-red-500">Failed to pay entrance fee</p>
            )}
        </div>
    );
}