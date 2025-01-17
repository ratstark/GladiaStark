"use client"
import { useRouter } from 'next/navigation';
interface FightButtonProps {
    children: React.ReactNode
    primary?: boolean
}

export function FightButton({ children, primary }: FightButtonProps) {
    const router = useRouter();

    const onClick = () => {
        router.push('/arena');
    }

    return (
        <button
            onClick={onClick}
            className={`
          stone-button
          px-8 py-4
          roman-title
          text-xl
          font-bold
          rounded
          transition-all
          duration-300
          ${primary ? 'text-gold' : 'text-gold border-opacity-50'}
          hover:border-opacity-100
          hover:shadow-lg
          hover:shadow-gold/20
        `}
        >
            {children}
        </button>
    )
}

