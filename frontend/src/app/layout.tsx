import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Token Swap — demo AMM",
  description: "Demo UI del AMM de producto constante con swap, liquidez y tema claro/oscuro",
  icons: { icon: "/favicon.svg" },
};

const themeBootScript = `
(function(){
  try {
    var k='swap-theme';
    var t=localStorage.getItem(k);
    if(t!=='light'&&t!=='dark'){
      t=window.matchMedia('(prefers-color-scheme: light)').matches?'light':'dark';
    }
    document.documentElement.setAttribute('data-theme', t);
  } catch(e) {
    document.documentElement.setAttribute('data-theme', 'dark');
  }
})();
`;

/**
 * Layout raíz (Server Component).
 */
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="es" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeBootScript }} />
      </head>
      <body>
        <main className="shell">{children}</main>
      </body>
    </html>
  );
}
