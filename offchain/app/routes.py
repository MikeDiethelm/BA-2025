import os
from flask import Blueprint, request, jsonify
from services.tx_service import TxService

bp = Blueprint('api', __name__)
tx_service = TxService()


@bp.route("/mint", methods=["POST"])
def mint():
    try:
        data = request.json
        tx_hash = tx_service.mint(
            data["assetName"], data.get("initialDatum", {}))
        return jsonify({"txHash": tx_hash}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@bp.route("/update", methods=["POST"])
def update():
    try:
        data = request.json
        tx_hash = tx_service.update(
            data["assetName"], data.get("newDatum", {}))
        return jsonify({"txHash": tx_hash}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@bp.route("/burn", methods=["POST"])
def burn():
    try:
        data = request.json
        tx_hash = tx_service.burn(data["assetName"])
        return jsonify({"txHash": tx_hash}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
