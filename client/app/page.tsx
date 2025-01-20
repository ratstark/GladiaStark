import { StarknetProvider } from './components/wallet/StarknetProvider'
import { StoneButton } from './components/StoneButton'
import { FightButton } from './components/FightButton'

export default function Home() {

  return (
    <StarknetProvider>
      <main className="min-h-screen">
        <section className="max-w-4xl mx-auto px-4 py-16 text-center space-y-16">
          <div className="space-y-4">
            <h1 className="roman-title text-4xl md:text-6xl font-bold glow-text">
              Step into the Arena. Fight for Glory.
            </h1>
            <p className="text-xl opacity-80">Your journey begins here.</p>
          </div>
          <div className="flex flex-col sm:flex-row gap-6 justify-center items-center">
            <FightButton>Fight</FightButton>
            <StoneButton>
              How It Works
            </StoneButton>
          </div>
          <footer className="space-y-4">
            <p className="text-sm opacity-80">
              Only the brave survive.
            </p>
          </footer>
        </section>
      </main>
    </StarknetProvider >
  )
}