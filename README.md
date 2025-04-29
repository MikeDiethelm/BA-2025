# Cardano-Implant 🦾  
Blockchain-gestützte Produktions- & Audit-Plattform für Implantate  
*(Cardano Mainnet + Hydra-L2, voll integrierbar in SAP/MES)*

![System-Architektur](./A_flowchart_diagram_in_the_digital_medium_illustra.png)

---

## Inhaltsverzeichnis
1. [Überblick & Architektur](#überblick--architektur)  
2. [Voraussetzungen (macOS)](#voraussetzungen-macos)  
3. [Schnellstart – 5-Minuten-Demo](#schnellstart--5-minuten--demo)  
4. [Projektstruktur](#projektstruktur)  
5. [Build & Run-Workflows](#build--run-workflows)  
6. [Tests & CI](#tests--ci)  
7. [Eigene Schlüssel / IDs](#eigene-schlüssel--ids)  
8. [Troubleshooting](#troubleshooting)  
9. [Lizenz](#lizenz)

---

## Überblick & Architektur
Die Plattform schreibt jeden Fertigungs- und QC-Schritt **unveränderlich** auf Cardano.  
Hohe TPS liefert ein **Hydra-Head** im Werk; L1-Anchors sichern globale Audit-Finalität.

