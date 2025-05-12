# Cardano-Implant 🦾  
Blockchain-gestützte Produktions- & Audit-Plattform für Implantate  
(Cardano Native Token + State-Thread-Token-Pattern, integrierbar in SAP / MES)

---

## Inhaltsverzeichnis
1. [Projektüberblick](#projektüberblick)  
2. [Architekturdiagramm](#architekturdiagramm)  
3. [Technische Umsetzung](#technische-umsetzung)  
4. [Voraussetzungen (macOS)](#voraussetzungen-macos)  
5. [Schnellstart](#schnellstart)  
6. [Projektstruktur](#projektstruktur)  
7. [Build- & Run-Workflows](#build--run-workflows)  
8. [Tests & CI](#tests--ci)  
9. [Eigene Schlüssel / IDs](#eigene-schlüssel--ids)  
10. [Troubleshooting](#troubleshooting)

---

## Projektüberblick
**Cardano-Implant** modelliert jedes hergestellte Implantat als **Cardano Native Token (CNT)** – abgesichert durch ein **Aiken-Policy-Script** im State-Thread-Token-Pattern (STT).  
So entsteht ein manipulationssicherer, lebens­zyklus­fähiger Digital-Twin:

* **Mint**: Token entsteht beim ersten Fertigungs­schritt.  
* **Update**: Datum der STT-Adresse wird in jeder Supply-Chain-Stufe erweitert.  
* **Burn / Transfer**: Abschluss oder Ownership-Wechsel (z. B. an Klinik).

Alle Off-Chain-Transaktionen werden über **MeshJS** (TypeScript) bzw. **PyCardano** gebaut und via **Blockfrost** auf dem **Cardano Preview-Testnetz** eingereicht.

---

## Architekturdiagramm
```mermaid
flowchart TD
    A[SAP / MES] -->|RFC JSON| B[Off-Chain Service<br/>(MeshJS / PyCardano)]
    B -->|REST| C[Blockfrost API]
    C -->|Tx Submit| D[Cardano Preview Testnet]
    D -->|State Thread Token| E[Implant-NFT + Datum]

    style A fill:#f9f,stroke:#333,stroke-width:2px
    style B fill:#bbf,stroke:#333,stroke-width:2px
    style C fill:#bfb,stroke:#333,stroke-width:2px
    style D fill:#fbf,stroke:#333,stroke-width:2px
    style E fill:#ffc,stroke:#333,stroke-width:2px
```

---

## Technische Umsetzung

### 1 · On-Chain (Smart Policies)
| Ziel | Tool | Datei |
|------|------|-------|
| Implant-NFT + STT-Policy | **Aiken** | `onchain/policies/implant_stt.ak` |

* NFT-Policy **prägt genau 1 Token** (`ImplantId`)  
* STT-Policy sichert, dass nur autorisierte Operator-Signaturen das Datum updaten.

Beispiel-Aiken-Snippet:
```rust
fn operator_authorised(ctx: ScriptContext) -> Bool {
  tx_signed_by(ctx, ctx.get_datum<TxDatum>().operator_pkh)
}
```

Kompilieren:
```bash
aiken build
aiken blueprint > onchain/blueprint.json   # erzeugt plutus.json
```

### 2 · Off-Chain (Tx-Builder)  
* **MeshJS** (TS) oder **PyCardano** für Mint-, Update-, Burn-Tx-Erstellung  
* Network-Layer: **Blockfrost** API (Preview-Testnetz)

Workflow (MeshJS):
```ts
import { TxBuilder, Data, BlockfrostProvider } from "@meshsdk/core";
const provider = new BlockfrostProvider("<BLOCKFROST_KEY>", "preview");
const tx = new TxBuilder()
   .mintAsset(policyId, assetName, 1n)
   .attachScript("onchain/blueprint.json")
   .payToContract(sttAddr, Data.to(sttDatum), "1500000")
   .complete();
await provider.submitTx(tx);
```

### 3 · Supply-Chain-Update (STT-Pattern)
1. Off-Chain-Service lädt aktuelles Datum der STT-Adresse.  
2. Fügt neuen Prozess-Hash hinzu (SHA-256 über SAP-JSON).  
3. Baut Sign-&-Update-Tx → Blockfrost.  
4. STT-Policy erlaubt Datum-Update nur, wenn:  
   * genau **1 NFT** bleibt an der Adresse  
   * Operator-Signatur passt  
   * Schritt-Sequenz korrekt (enum → Aiken-Match).

### 4 · Datenschutz
* Vollständiges SAP-JSON liegt verschlüsselt (AES-256) in `db/patients`.  
* On-Chain nur Hash (`metaHash`) → DSGVO-konform.

---

## Voraussetzungen (macOS)

| Tool | Version ≥ | Installation |
|------|-----------|--------------|
| Git | 2.40 | `brew install git` |
| Aiken CLI | 1.0-beta | `curl -sSfL https://install.aiken-lang.org | bash` |
| Node.js | 20 | `brew install node` |
| pnpm | 8 | `npm i -g pnpm` |
| Docker Desktop | 25.x | <https://www.docker.com/products/docker-desktop> |
| VS Code + Dev Containers | – | Extensions: *Dev Containers*, *Aiken Syntax* |

---

## Schnellstart
```bash
# Repo klonen
git clone https://github.com/<org>/cardano-implant.git
cd cardano-implant

# 1. On-Chain kompilieren
aiken build && aiken blueprint > onchain/blueprint.json

# 2. Off-Chain-Service installieren & starten
pnpm -C offchain install
BLOCKFROST_KEY=<dein-key> pnpm -C offchain dev
```

---

## Projektstruktur
```plaintext
onchain/            Aiken-Policies + blueprint.json
offchain/           MeshJS (Tx-Builder + REST-API)
db/                 AES-verschlüsselte Patientendaten
sap/                RFC-Stub (ABAP)
docs/               Mermaid-Diagramme etc.
```

---

## Build- & Run-Workflows

| Aufgabe | Befehl |
|---------|--------|
| Aiken Compile | `aiken build` |
| Blueprint exportieren | `aiken blueprint > onchain/blueprint.json` |
| Off-Chain build | `pnpm -C offchain build` |
| Off-Chain dev | `pnpm -C offchain dev` |

---

## Tests & CI
* **On-Chain-Tests:** `aiken test`  
* **Off-Chain-Unit-Tests:** Jest / PyTest (nach Wahl)  
* **CI/CD:** GitHub Actions → Aiken-Build + Off-Chain-Tests + Preview-Deploy

---

## Eigene Schlüssel / IDs

| Was | Wo | Hinweis |
|-----|----|---------|
| Blockfrost-API-Key | ENV `BLOCKFROST_KEY` | kostenlos auf blockfrost.io |
| Operator-Skeys | `offchain/keys/` | `cardano-cli address key-gen` |
| AES-Key | ENV `PATIENT_KEY` | 32-Byte Hex |

---

## Troubleshooting

| Problem | Lösung |
|---------|--------|
| *Token minten schlägt fehl* | Preview-Faucet ADA holen & UTxO richtig setzen |
| *Script Redeemer mismatch* | Blueprint neu generieren + Policy ID prüfen |
| *Blockfrost 403* | Projekt-ID → Preview, nicht Mainnet |

---

## Lizenz
MIT – frei nutz- & anpassbar.  
