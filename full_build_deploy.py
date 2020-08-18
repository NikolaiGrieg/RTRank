from py.deployment.build_zip import zipFilesInDir, include_filter
from py.deployment.deploy import deploy
from py.deployment.deploy_util import get_latest_build_and_increment
from py.main import regenerate_data
from rootfile import ROOT_DIR

regenerate_data()

print("Building")
new_build_name = get_latest_build_and_increment()
zipFilesInDir(ROOT_DIR, ROOT_DIR + f"\\build\\{new_build_name}", include_filter)

print("Deploying")
deploy()
