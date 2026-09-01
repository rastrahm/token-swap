"use client";

import Link from "next/link";
import { AppToolbar } from "@/components/AppToolbar";

/**
 * Manual in-app: instalación, uso de la UI y resolución de problemas.
 */
export default function AyudaPage() {
  return (
    <div className="app-grid help-manual">
      <header className="hero">
        <AppToolbar showHome />
        <p className="brand">Ayuda</p>
        <h1 className="headline">Manual de la demo AMM</h1>
        <p className="lede">
          Guía para arrancar Anvil, conectar la wallet y operar swap / liquidez en el par ALPHA–BETA.
        </p>
      </header>

      <nav className="panel" aria-label="Índice">
        <h2 className="panel-title">Índice</h2>
        <ul className="help-toc">
          <li><a href="#setup">Instalación</a></li>
          <li><a href="#wallet">Wallet</a></li>
          <li><a href="#interfaz">Interfaz</a></li>
          <li><a href="#tokens">Par de tokens</a></li>
          <li><a href="#pool">Panel Pool</a></li>
          <li><a href="#swap">Swap</a></li>
          <li><a href="#liquidez">Liquidez</a></li>
          <li><a href="#conceptos">Conceptos AMM</a></li>
          <li><a href="#problemas">Problemas</a></li>
        </ul>
      </nav>

      <section className="panel" id="setup">
        <h2 className="panel-title">1. Instalación local</h2>
        <p className="help-subtitle">Requisitos</p>
        <ul className="help-list">
          <li><strong>Foundry</strong> (<code>anvil</code>, <code>forge</code>)</li>
          <li><strong>Node ≥ 20.19</strong> (ver <code>frontend/.nvmrc</code>)</li>
          <li><strong>MetaMask</strong> u otra wallet con EIP-1193</li>
        </ul>
        <p className="help-subtitle">Pasos</p>
        <ol className="help-list">
          <li>
            Terminal 1 — cadena local: <code>anvil</code>
          </li>
          <li>
            Terminal 2 — deploy de contratos:
            <br />
            <code>
              export PATH=&quot;$HOME/.foundry/bin:$PATH&quot;
              <br />
              forge script script/Deploy.s.sol:Deploy --rpc-url http://127.0.0.1:8545 --broadcast
            </code>
          </li>
          <li>
            Copiá del log las addresses a <code>frontend/.env.local</code> (plantilla en{" "}
            <code>.env.example</code>). Ver también <code>doc/DEPLOY.md</code>.
          </li>
          <li>
            Terminal 3 — frontend:
            <br />
            <code>cd frontend && npm install && npm run dev</code>
          </li>
          <li>
            Abrí <Link href="/">http://127.0.0.1:3000</Link>
          </li>
        </ol>
        <p className="help-callout">
          El script de deploy crea dos tokens demo (ALPHA / BETA), la factory, el router, el par y
          deposita liquidez inicial (10&nbsp;000 de cada token).
        </p>
      </section>

      <section className="panel" id="wallet">
        <h2 className="panel-title">2. Conectar la wallet</h2>
        <ol className="help-steps">
          <li>
            En MetaMask, agregá una red personalizada: RPC{" "}
            <code>http://127.0.0.1:8545</code>, chain ID <strong>31337</strong>, símbolo ETH.
          </li>
          <li>
            Importá la cuenta de prueba Anvil #0 (la que usa el deploy). Clave privada por defecto:
            <br />
            <code>0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80</code>
          </li>
          <li>
            En la app, pulsá <strong>Conectar wallet</strong>. Si la red no coincide, la UI pedirá
            cambiar a 31337.
          </li>
          <li>
            Tras conectar verás tu address acortada en la cabecera. Todas las transacciones (swap,
            liquidez, mint) requieren wallet conectada.
          </li>
        </ol>
      </section>

      <section className="panel" id="interfaz">
        <h2 className="panel-title">3. Recorrido por la interfaz</h2>
        <table className="help-table">
          <thead>
            <tr>
              <th>Sección</th>
              <th>Para qué sirve</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Barra superior</td>
              <td>Volver al swap, abrir esta ayuda, alternar tema claro/oscuro.</td>
            </tr>
            <tr>
              <td>Par de tokens</td>
              <td>Elegir qué ERC-20 son ALPHA y BETA; el par se busca en la factory.</td>
            </tr>
            <tr>
              <td>Pool</td>
              <td>Reservas on-chain, tus balances y LP; fee del protocolo (0,3&nbsp;%).</td>
            </tr>
            <tr>
              <td>Swap</td>
              <td>Intercambiar un token por el otro con protección de slippage.</td>
            </tr>
            <tr>
              <td>Liquidez</td>
              <td>Depositar o retirar liquidez; acuñar tokens demo en Anvil.</td>
            </tr>
          </tbody>
        </table>
        <p className="help-callout">
          Los paneles Pool, Swap y Liquidez solo aparecen cuando el par está resuelto (address de par
          válida). Si ves error en «Par de tokens», corregí las addresses o usá Restaurar deploy.
        </p>
      </section>

      <section className="panel" id="tokens">
        <h2 className="panel-title">4. Configurar ALPHA y BETA</h2>
        <ol className="help-steps">
          <li>
            <strong>ALPHA / BETA</strong> son etiquetas de la UI para el token de entrada A y el B.
            Por defecto coinciden con TokenA y TokenB del deploy.
          </li>
          <li>
            Editá las addresses <code>0x…</code> y pulsá <strong>Aplicar</strong>. La app consulta la
            factory y muestra el par activo si existe.
          </li>
          <li>
            <strong>⇄ Invertir A/B</strong> intercambia qué token se muestra como ALPHA y cuál como
            BETA (útil para cambiar la dirección del swap sin reescribir addresses).
          </li>
          <li>
            <strong>Restaurar deploy</strong> vuelve a las addresses de <code>.env.local</code> y
            borra el override guardado en el navegador.
          </li>
        </ol>
        <p className="muted tiny">
          La elección se persiste en <code>localStorage</code> (<code>swap-token-pair</code>).
        </p>
      </section>

      <section className="panel" id="pool">
        <h2 className="panel-title">5. Panel Pool</h2>
        <dl className="help-dl">
          <div>
            <dt>Reservas ALPHA / BETA</dt>
            <dd>
              Cantidad de cada token que custodia el contrato del par. Definen el precio instantáneo
              y el output de un swap.
            </dd>
          </div>
          <div>
            <dt>Tu ALPHA / Tu BETA</dt>
            <dd>Balance ERC-20 de tu wallet conectada (no incluye LP).</dd>
          </div>
          <div>
            <dt>LP balance</dt>
            <dd>
              Tokens de liquidez (TSLP) que poseés. Representan tu participación en el pool; se usan
              para retirar liquidez.
            </dd>
          </div>
          <div>
            <dt>Fee swap 0,30&nbsp;%</dt>
            <dd>
              Comisión del AMM en cada swap; queda en el pool y beneficia a los proveedores de
              liquidez.
            </dd>
          </div>
        </dl>
        <p className="muted tiny">Los valores se actualizan solos cada ~12 segundos.</p>
      </section>

      <section className="panel" id="swap">
        <h2 className="panel-title">6. Hacer un swap</h2>
        <ol className="help-steps">
          <li>
            Elegí la dirección con las pestañas <strong>ALPHA → BETA</strong> o{" "}
            <strong>BETA → ALPHA</strong>.
          </li>
          <li>
            Ingresá la <strong>cantidad</strong> del token de entrada (decimales estándar 18 en la
            demo).
          </li>
          <li>
            Revisá el <strong>output estimado</strong> debajo del formulario (ya incluye fee 0,3&nbsp;%).
          </li>
          <li>
            Configurá <strong>Slippage (bps)</strong>: puntos básicos de tolerancia. Ejemplo:{" "}
            <code>50</code> = 0,5&nbsp;% — si el output real cae por debajo, la tx revierte.
          </li>
          <li>
            Pulsá <strong>Swap</strong>. MetaMask pedirá aprobar el router si es la primera vez y
            luego confirmar la transacción.
          </li>
        </ol>
        <p className="help-callout">
          Con poca liquidez o montos grandes, el precio se mueve más (deslizamiento). Subí el
          slippage solo lo necesario; en mainnet un slippage alto aumenta el riesgo de sandwich.
        </p>
      </section>

      <section className="panel" id="liquidez">
        <h2 className="panel-title">7. Liquidez (depositar y retirar)</h2>
        <p className="help-subtitle">Depositar</p>
        <ol className="help-steps">
          <li>Pestaña <strong>Depositar</strong>.</li>
          <li>
            Indicá cuánto ALPHA y BETA querés aportar. En un pool existente el router ajusta la
            proporción según las reservas; en la demo podés usar cantidades similares (ej. 10 / 10).
          </li>
          <li>
            <strong>Añadir liquidez</strong> — aprobá ambos tokens si hace falta. Recibirás LP
            (TSLP) en tu wallet.
          </li>
        </ol>
        <p className="help-subtitle">Retirar</p>
        <ol className="help-steps">
          <li>Pestaña <strong>Retirar</strong>.</li>
          <li>
            Ingresá la cantidad de <strong>LP a quemar</strong> (máximo tu LP balance del panel Pool).
          </li>
          <li>
            <strong>Retirar liquidez</strong> — el router transfiere LP al par, quema y devuelve
            ALPHA y BETA proporcionalmente.
          </li>
        </ol>
        <p className="help-subtitle">Mint demo 10k</p>
        <p className="muted tiny">
          Solo en tokens <code>MockERC20</code> del deploy: acuña 10&nbsp;000 ALPHA y 10&nbsp;000 BETA
          a tu wallet si te quedaste sin saldo para probar swaps.
        </p>
      </section>

      <section className="panel" id="conceptos">
        <h2 className="panel-title">8. Conceptos del AMM</h2>
        <dl className="help-dl">
          <div>
            <dt>Producto constante (x · y = k)</dt>
            <dd>
              Las reservas de ambos tokens deben mantener una relación de producto; al swap, el input
              compensa el output y el fee hace que k no decrezca.
            </dd>
          </div>
          <div>
            <dt>Router vs Par</dt>
            <dd>
              El <strong>par</strong> custodia tokens y ejecuta la fórmula; el <strong>router</strong>{" "}
              facilita approve, transfer y slippage (<code>amountOutMin</code> + deadline).
            </dd>
          </div>
          <div>
            <dt>LP (TSLP)</dt>
            <dd>
              Certificado de depósito en el pool. Primer mint bloquea liquidez mínima en{" "}
              <code>address(0)</code> (anti-inflation).
            </dd>
          </div>
        </dl>
      </section>

      <section className="panel" id="problemas">
        <h2 className="panel-title">9. Problemas frecuentes</h2>
        <dl className="help-dl">
          <div>
            <dt>«Red incorrecta»</dt>
            <dd>MetaMask debe estar en chain <strong>31337</strong> apuntando a Anvil.</dd>
          </div>
          <div>
            <dt>«No existe par para esos tokens»</dt>
            <dd>
              Las addresses no tienen par en la factory. Usá Restaurar deploy o creá el par on-chain
              antes de Aplicar.
            </dd>
          </div>
          <div>
            <dt>Swap revierte por slippage</dt>
            <dd>
              Subí slippage (bps) o reducí el monto. Otro swap pudo mover el precio entre la
              estimación y la confirmación.
            </dd>
          </div>
          <div>
            <dt>Transacción pendiente / sin fondos</dt>
            <dd>
              La cuenta Anvil necesita ETH para gas. Usá Mint demo o la cuenta #0 del deploy que ya
              tiene tokens y ETH.
            </dd>
          </div>
          <div>
            <dt>Anvil reiniciado</dt>
            <dd>
              Las addresses cambian si volvés a desplegar. Actualizá <code>.env.local</code> y
              Restaurar deploy; reiniciá <code>npm run dev</code> si cambiaste env.
            </dd>
          </div>
          <div>
            <dt>Tema no se guarda</dt>
            <dd>
              Clave <code>swap-theme</code> en <code>localStorage</code>. Modo claro/oscuro en la
              barra superior.
            </dd>
          </div>
          <div>
            <dt>Error 500 al abrir <code>/</code></dt>
            <dd>
              Caché de desarrollo corrupta (<code>.next</code>), habitual con Turbopack + recargas
              en caliente o si corrés <code>npm run build</code> con el dev server activo.
              <br />
              <strong>Solución:</strong> pará el servidor (<code>Ctrl+C</code>), luego en{" "}
              <code>frontend/</code>:
              <br />
              <code>npm run dev:clean</code>
              <br />
              Si el puerto 3000 queda ocupado: <code>fuser -k 3000/tcp</code> y volvé a ejecutar{" "}
              <code>dev:clean</code>. Recargá el navegador con <code>Ctrl+Shift+R</code>.
            </dd>
          </div>
          <div>
            <dt>Avisos en consola (<code>contentscript.js</code>, ObjectMultiplex)</dt>
            <dd>
              Provienen de la <strong>extensión de wallet</strong> (p. ej. MetaMask), no del frontend
              del AMM. Son habituales con recargas en caliente (Next.js dev) y no afectan las
              transacciones. Si molestan: probá en ventana de incógnito solo con una extensión, o
              ignorá los warnings en desarrollo.
            </dd>
          </div>
        </dl>
      </section>
    </div>
  );
}
