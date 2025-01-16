interface StoneButtonProps {
    children: React.ReactNode
    primary?: boolean
    onClick?: () => void
}

export function StoneButton({ children, primary, onClick }: StoneButtonProps) {
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

