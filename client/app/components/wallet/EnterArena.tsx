"use client"
import { useAccount, useExplorer, useTransactionReceipt } from '@starknet-react/core'
import { useCallback, useState, useEffect } from 'react'
import { StoneButton } from '../StoneButton'

const ARENA_CONTRACT = '0x03378dcd8e66d245468a57839d29c8a79347c76ea01afa19559ceab49b45fd6f'

const SuccessPopup = ({ 
    onClose,
    error,
    txnHash,
    status,
    isError,
    receiptError,
    explorer
}: { 
    onClose: () => void,
    error?: string,
    txnHash?: string,
    status?: string,
    isError?: boolean,
    receiptError?: Error,
    explorer: any
}) => (
    <div style={{
        position: 'fixed',
        bottom: '20px',
        right: '20px',
        background: error || isError ? '#f44336' : '#4CAF50',
        color: 'white',
        padding: '1rem',
        borderRadius: '4px',
        boxShadow: '0 2px 5px rgba(0,0,0,0.2)',
        zIndex: 1000,
        maxWidth: '400px'
    }}>
        <div style={{ marginBottom: '10px', display: 'flex', justifyContent: 'space-between' }}>
            <span>{error || isError ? 'Transaction Failed' : 'Transaction successful!'}</span>
            <button 
                onClick={onClose}
                style={{
                    background: 'transparent',
                    border: 'none',
                    color: 'white',
                    cursor: 'pointer'
                }}
            >
                ✕
            </button>
        </div>
        {error && (
            <div style={{ marginTop: '10px' }}>
                Error: {error}
            </div>
        )}
        {txnHash && (
            <div style={{ fontSize: '0.9em' }}>
                <div>Status: {status}</div>
                {isError && <div>Error: {receiptError?.message}</div>}
                <a
                    href={explorer.transaction(txnHash)}
                    target="blank"
                    rel="noreferrer"
                    style={{ color: 'white', textDecoration: 'underline' }}
                >
                    View on Explorer
                </a>
            </div>
        )}
    </div>
)

export const EnterArena = () => {
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
                        contractAddress: ARENA_CONTRACT,
                        entrypoint: 'enter_arena',
                        calldata: [account?.address, 11],
                    }
                ])
                if (!result?.transaction_hash) {
                    throw new Error("No transaction hash received")
                }
                setTxnHash(result.transaction_hash)
            } catch (e) {
                console.error(e)
                setError(e instanceof Error ? e.message : "Failed to enter arena")
            } finally {
                setSubmitted(false)
            }
        },
        [account],
    )

    const buttonText = () => {
        if (submitted) return 'Entering...'
        if (isPending && txnHash) return 'Processing...'
        return 'Enter Arena'
    }

    if (!account) return null

    return (
        <div>
            <StoneButton
                onClick={() => execute()}
            >
                {buttonText()}
            </StoneButton>
            
            {(showSuccess || error || txnHash) && (
                <SuccessPopup 
                    onClose={() => {
                        setShowSuccess(false)
                        setError(undefined)
                    }}
                    error={error}
                    txnHash={txnHash}
                    status={status}
                    isError={isError}
                    explorer={explorer}
                />
            )}
        </div>
    )
}