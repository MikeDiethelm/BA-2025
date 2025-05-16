import * as dotenv from "dotenv";
dotenv.config();

import express from "express";
import bodyParser from "body-parser";
import * as fs from "fs";
import * as path from "path";
import { TxBuilder, Data, BlockfrostProvider } from "@meshsdk/core";

const blueprintPath = path.resolve(__dirname, "../../onchain/blueprint.json");
const blueprint = JSON.parse(fs.readFileSync(blueprintPath, "utf-8"));

const sttMintValidator = blueprint.validators.find(
  (v: any) => v.title === "implant_stt.implant_stt.mint"
)!;
const sttScript = sttMintValidator.compiledCode;
const policyId = sttMintValidator.hash;

const BLOCKFROST_KEY = process.env.BLOCKFROST_KEY!;
const provider = new BlockfrostProvider(BLOCKFROST_KEY, "preview");

const app = express();
app.use(bodyParser.json());
const PORT = +process.env.PORT!;

function newBuilder() {
  return new TxBuilder()
    .setProvider(provider)
    .attachScript(Buffer.from(sttScript, "hex"))
    .setPolicyId(policyId);
}

app.post("/mint", async (req, res) => {
  try {
    const { assetName, initialDatum } = req.body as {
      assetName: string;
      initialDatum: Record<string, any>;
    };

    const tx = newBuilder()
      .mintAsset(policyId, assetName, 1n)
      .payToContract(
        "<DEINE_STT_SCRIPT_ADDRESS>",
        Data.to(initialDatum),
        "1500000"
      )
      .complete();

    const txHash = await provider.submitTx(tx);
    res.json({ txHash });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: (error as Error).message });
  }
});

app.post("/update", async (req, res) => {
  try {
    const { assetName, newDatum } = req.body as {
      assetName: string;
      newDatum: Record<string, any>;
    };

    const tx = newBuilder()
      .mintAsset(policyId, assetName, 0n)
      .payToContract(
        "<DEINE_STT_SCRIPT_ADDRESS>",
        Data.to(newDatum),
        "1500000"
      )
      .complete();

    const txHash = await provider.submitTx(tx);
    res.json({ txHash });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: (error as Error).message });
  }
});

app.post("/burn", async (req, res) => {
  try {
    const { assetName } = req.body as { assetName: string };
    const tx = newBuilder().mintAsset(policyId, assetName, -1n).complete();
    const txHash = await provider.submitTx(tx);
    res.json({ txHash });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: (error as Error).message });
  }
});

app.listen(PORT, () => {
  console.log(`🛰️  Offchain-Service läuft auf http://localhost:${PORT}`);
});
