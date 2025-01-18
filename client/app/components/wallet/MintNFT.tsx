"use client"
import { useAccount, useExplorer, useTransactionReceipt } from '@starknet-react/core'
import { useCallback, useState, useEffect } from 'react'
import { StoneButton } from '../StoneButton'

const MINT_CONTRACT = '0x03378dcd8e66d245468a57839d29c8a79347c76ea01afa19559ceab49b45fd6f'

const SuccessPopup = ({ onClose }: { onClose: () => void }) => (
    <div style={{
        position: 'fixed',
        bottom: '20px',
        right: '20px',
        background: '#4CAF50',
        color: 'white',
        padding: '1rem',
        borderRadius: '4px',
        boxShadow: '0 2px 5px rgba(0,0,0,0.2)',
        zIndex: 1000
    }}>
        Transaction successful!
        <button 
            onClick={onClose}
            style={{
                marginLeft: '10px',
                background: 'transparent',
                border: 'none',
                color: 'white',
                cursor: 'pointer'
            }}
        >
            ✕
        </button>
    </div>
)

export const MintNFT = () => {
    const [submitted, setSubmitted] = useState<boolean>(false)
    const [showSuccess, setShowSuccess] = useState(false)
    const [error, setError] = useState<string>()
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

    const execute = useCallback(
        async () => {
            if (!account) return
            setSubmitted(true)
            setError(undefined)
            setTxnHash(undefined)
            try {
                const result = await account.execute([
                    {
                        contractAddress: MINT_CONTRACT,
                        entrypoint: 'safeMint',
                        calldata: [account?.address, "bafkreiejcsdzrsytzejjjv5k2v6ecsdb3dzyn4xsdbmd2a2e7irlfnvseq"],
                    }
                ])
                if (!result?.transaction_hash) {
                    throw new Error("No transaction hash received")
                }
                setTxnHash(result.transaction_hash)
            } catch (e) {
                console.error(e)
                setError(e instanceof Error ? e.message : "Transaction failed")
            } finally {
                setSubmitted(false)
            }
        },
        [account],
    )

    const buttonText = () => {
        if (submitted) return 'Submitting...'
        if (isPending && txnHash) return 'Processing...'
        if (isSuccess) return 'Mint Another'
        return 'Mint NFT'
    }

    if (!account) return null

    return (
        <div>
            <StoneButton
                onClick={() => execute()}
            >
                {buttonText()}
            </StoneButton>
            {error && (
                <div style={{ color: 'red', marginTop: '10px' }}>
                    Error: {error}
                </div>
            )}
            {txnHash && (
                <div>
                    Status: {status}
                    {isError && <div style={{ color: 'red' }}>Error: {receiptError?.message}</div>}
                    <a
                        href={explorer.transaction(txnHash)}
                        target="blank"
                        rel="noreferrer"
                    >
                        View on Explorer
                    </a>
                </div>
            )}
            {showSuccess && (
                <SuccessPopup onClose={() => setShowSuccess(false)} />
            )}
        </div>
    )
}