import os
import json
from pycardano import *
from dotenv import load_dotenv

load_dotenv()


class TxService:
    def __init__(self):
        self.context = BlockFrostChainContext(
            os.getenv("BLOCKFROST_KEY"), Network.TESTNET)
        with open("onchain/blueprint.json") as f:
            blueprint = json.load(f)
        validator = next(
            v for v in blueprint["validators"] if v["title"] == "implant_stt.implant_stt.mint")
        self.compiled_code = bytes.fromhex(validator["compiledCode"])
        self.policy_id = validator["hash"]
        self.script = PlutusV2Script(self.compiled_code)
        self.script_address = Address(plutus_script_hash(
            self.script), network=Network.TESTNET)
        self.skey = PaymentSigningKey.load(os.getenv("PAYMENT_SKEY"))
        self.vkey = PaymentVerificationKey.load(os.getenv("PAYMENT_VKEY"))

    def mint(self, asset_name, initial_datum):
        builder = TransactionBuilder(self.context)
        output = TransactionOutput(
            self.script_address,
            Value.from_primitive(
                [1500000, {self.policy_id: {asset_name.encode(): 1}}])
        )
        builder.add_output(output)
        signed_tx = builder.build_and_sign([self.skey], change_address=Address(
            self.vkey.hash(), network=Network.TESTNET))
        self.context.submit_tx(signed_tx)
        return signed_tx.id

    def update(self, asset_name, new_datum):
        # Hier analog zu mint implementieren, Datum aktualisieren
        return self.mint(asset_name, new_datum)

    def burn(self, asset_name):
        builder = TransactionBuilder(self.context)
        signed_tx = builder.build_and_sign([self.skey], change_address=Address(
            self.vkey.hash(), network=Network.TESTNET))
        self.context.submit_tx(signed_tx)
        return signed_tx.id
