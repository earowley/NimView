import { useState } from 'react'
import reactLogo from './assets/react.svg'
import nimLogo from './assets/nim.svg'
import viteLogo from '/vite.svg'
import './App.css'

function App() {
  const [syncResult, setSyncResult] = useState(undefined);
  const val = [1, 2, 3, 4, 5];

  return (
    <>
      <div>
        <a href="https://vitejs.dev" target="_blank">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
        <a href="https://nim-lang.org" target="_blank">
          <img src={nimLogo} className="logo" alt="Nim logo" />
        </a>
      </div>
      <h1>Vite + React + Nim</h1>
      <div className="card">
        <button onClick={async () => {
          let sr = accumulate(val);
          setSyncResult(await sr);
        }}>
          Test Bindings
        </button>
        <p>
          {syncResult}
        </p>
      </div>
      <p className="read-the-docs">
        Click on the Vite and React logos to learn more
      </p>
    </>
  )
}

export default App
