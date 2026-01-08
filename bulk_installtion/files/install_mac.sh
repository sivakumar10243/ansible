#!/bin/bash
set -e

curl -L -o faveo-agent 'https://agentsw.faveodemo.com/api/agent/download/?platform=darwin&architecture=arm64' && chmod +x faveo-agent && sudo ./faveo-agent -m install --api https://agentsw.faveodemo.com --client-id 1 --site-id 1 --asset_type_id 34 --auth rJJNdXm65UEWP4cF6X0z8sgFAIMIydYlQ0MpeCRCKFqfrcaPoKAiP3sElmJ7 -silent -with_zoho=0