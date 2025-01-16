import './globals.css'
import { Cinzel } from 'next/font/google'
import { ChakraProvider } from '@chakra-ui/react'

const cinzel = Cinzel({
  subsets: ['latin'],
  variable: '--font-cinzel',
  weight: ['400', '700']
})

export const metadata = {
  title: 'Gladiator Arena - Step into Glory',
  description: 'Fight for honor in the ancient arena',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <ChakraProvider>
        <body className={`${cinzel.variable}`}>{children}</body>
      </ChakraProvider>
    </html >
  )
}

