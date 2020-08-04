import json

import requests

from py.secret_handler import get_deploy_key
from rootfile import ROOT_DIR

"""
{
    "id": 7717,
    "gameVersionTypeID": 517,
    "name": "8.3.0",
    "slug": "8-3"
}
"""

with open(ROOT_DIR + "/build/RTRank_Beta2.zip", 'rb') as f:  # todo recursive search based on criterias
    token = get_deploy_key()
    headers = {"X-Api-Token": token}

    data = {
        "metadata": json.dumps({
            "changelog": "Backend fixes + data load",
            "changelogType": "text",
            "gameVersions": [7717],
            "releaseType": "beta",
            "relations": {
                "projects": [{
                    "slug": "details",
                    "type": "requiredDependency"
                }]
            }
        })
    }

    response = requests.post('https://wow.curseforge.com/api/projects/397496/upload-file',
                             data=data,
                             files={"file": f},
                             headers=headers)
    content = json.loads(response.content)
    print(content)
