import json

import requests

from py.deployment.deploy_util import get_newest_build_file
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


def deploy():
    newest_file, major, _ = get_newest_build_file()

    with open(ROOT_DIR + f"/build/{newest_file}", 'rb') as f:
        token = get_deploy_key()
        headers = {"X-Api-Token": token}

        data = {
            "metadata": json.dumps({
                "changelog": "Updated data",
                "changelogType": "text",
                "gameVersions": [7717],
                "releaseType": major.lower(),
                "relations": {
                    "projects": [{
                        "slug": "details",
                        "type": "requiredDependency"
                    }]
                }
            })
        }
        # print(f"PH posting file: {newest_file}")

        response = requests.post('https://wow.curseforge.com/api/projects/397496/upload-file',
                                 data=data,
                                 files={"file": f},
                                 headers=headers)
        content = json.loads(response.content)
        print(content)
