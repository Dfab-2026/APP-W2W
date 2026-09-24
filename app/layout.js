import './globals.css';
import { Toaster } from '@/components/ui/sonner';

export const viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
};

export const metadata = {
  title: 'Work2Wish – Find day-work or hire skilled workers',
  description: 'Work2Wish connects skilled workers with employers for daily and short-term jobs.',
  manifest: '/manifest.webmanifest',
  applicationName: 'Work2Wish',
  appleWebApp: {
    capable: true,
    title: 'Work2Wish',
    statusBarStyle: 'default',
  },
  icons: {
    icon: [
      { url: '/work2wish-icon-192.png', sizes: '192x192', type: 'image/png' },
      { url: '/work2wish-icon-512.png', sizes: '512x512', type: 'image/png' },
    ],
    apple: [{ url: '/apple-touch-icon.png', sizes: '180x180', type: 'image/png' }],
  },
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-background text-foreground antialiased">
        {children}
        <Toaster richColors position="top-center" />
      </body>
    </html>
  );
}
