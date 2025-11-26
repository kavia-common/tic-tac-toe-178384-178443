import React from "react";
import { createRoot } from "react-dom/client";
import "./index.css";

function App() {
  // PUBLIC_INTERFACE
  /**
   * Root App component for the Tic-Tac-Toe web application.
   * This is a minimal placeholder to enable successful startup.
   */
  return (
    <main style={{ display: "grid", placeItems: "center", minHeight: "100vh", fontFamily: "system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif" }}>
      <section style={{ textAlign: "center" }}>
        <h1>Tic-Tac-Toe</h1>
        <p>App is set up correctly. Start command is available.</p>
      </section>
    </main>
  );
}

const container = document.getElementById("root");
const root = createRoot(container);
root.render(<App />);
