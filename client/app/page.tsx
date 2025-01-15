import { StarknetProvider } from './components/wallet/StarknetProvider'
import { ConnectWallet } from './components/wallet/ConnectWallet'
import { TransferEth } from './components/wallet/TransferEth'
import { ChakraProvider } from '@chakra-ui/react'

function Home() {
  return (
    <ChakraProvider>
      <StarknetProvider>
        <ConnectWallet />
        <TransferEth />
      </StarknetProvider>
    </ChakraProvider>
  )
}
export default Home