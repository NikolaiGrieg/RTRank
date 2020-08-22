import os
from json import JSONDecodeError

from py.deployment.build_zip import zipFilesInDir, include_filter
from py.deployment.deploy import deploy
from py.deployment.deploy_util import get_latest_build_and_increment
from py.main import regenerate_data
from rootfile import ROOT_DIR


def retry_wrap_func(func, max_retries):
    """
    Retries data loading function in case of error due to empty response.
    :param func:
    :param max_retries:
    :return:
    """
    retries = 0
    while retries < max_retries:  # retries in case of receiving empty responses (happens transiently)
        try:
            func()
            break
        except JSONDecodeError as e:
            retries += 1
            if retries < max_retries:
                print(f"JSONDecodeError hit, at retries ({retries}):")
                print(e)
            else:
                raise e


if __name__ == '__main__':
    retry_wrap_func(regenerate_data, 30)  # function will restart from checkpoint (caching spec:encounters processed)

    print("Building")
    new_build_name = get_latest_build_and_increment()
    zipFilesInDir(ROOT_DIR, ROOT_DIR + f"/build/{new_build_name}", include_filter)
    print(f"New build name: {new_build_name}")

    print("Deploying")
    deploy()
